// Created by Julian Dunskus

import Foundation
import Promise

typealias TaskResult = (data: Data, response: HTTPURLResponse)

final class Client {
	static let shared = Client()
	static let apiVersion = 1
	
	/// the user we're currently logged in as
	var user: User? {
		didSet {
			guard let user = user else { return }
			if let old = oldValue, user.id != old.id {
				storage = Storage() // invalidate after switching user
			}
		}
	}
	
	/// current local representation of all the data
	var storage = Storage()
	
	private let domainOverrides: [String: URL] = {
		let path = Bundle.main.path(forResource: "domains.private", ofType: "json")!
		do {
			let raw = try Data(contentsOf: URL(fileURLWithPath: path))
			return try JSONDecoder().decode(from: raw)
		} catch {
			print("Could not load servers!", error.localizedFailureReason)
			dump(error)
			return [:]
		}
	}()
	/// used when there's no domain override for the given username
	private let fallbackDomain = URL(string: "https://dev.app.mangel.io")!
	
	private let urlSession = URLSession.shared
	
	private let requestEncoder = JSONEncoder() <- {
		$0.dateEncodingStrategy = .iso8601
	}
	private let responseDecoder = JSONDecoder() <- {
		$0.dateDecodingStrategy = .iso8601
	}
	
	/// the backlog of requests that couldn't be sent due to connection issues
	private var backlog = Backlog() {
		didSet { try? saveBacklog() }
	}
	/// used to automatically attempt to clear the backlog at regular intervals
	private var backlogClearingTimer: Timer!
	/// while this is true, all requests will be dispatched directly and on the global queue to avoid deadlocks
	private var isClearingBacklog = false
	/// any dependent requests are executed on this queue, so as to avoid bad interleavings and races and such
	private let linearQueue = DispatchQueue(label: "dependent request execution")
	/// saving to disk is done on this queue to avoid clogging up other queues
	private let savingQueue = DispatchQueue(label: "saving client")
	
	private init() {
		loadShared()
		backlogClearingTimer = .scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
			self.tryToClearBacklog()
		}
	}
	
	/// call this e.g. when the device regains its internet connection
	func tryToClearBacklog() {
		linearQueue.async {
			try? self.clearBacklog()
		}
	}
	
	func send<R: Request>(_ request: R) -> Future<R.ExpectedResponse> {
		return dispatch(request)
			.map { taskResult in try self.extractData(from: taskResult, for: request) }
			.then { response in
				DispatchQueue.main.sync { request.applyToClient(response) } // to avoid data races
		}
	}
	
	private func dispatch<R: Request>(_ request: R) -> Future<TaskResult> {
		if R.isIndependent || isClearingBacklog {
			return startTask(for: request)
		} else {
			return Future(asyncOn: linearQueue) {
				do {
					try self.clearBacklog()
					return try self.startTask(for: request).await()
				} catch RequestError.communicationError(let error) {
					print("Communication error during request \(request.method): \(error.localizedFailureReason)")
					dump(error)
					self.backlog.appendIfPossible(request)
					self.saveShared()
					throw RequestError.communicationError(error)
				}
			}
		}
	}
	
	/// only ever run this on linearQueue
	private func clearBacklog() throws {
		isClearingBacklog = true
		defer { isClearingBacklog = false }
		
		while let request = backlog.first {
			do {
				try request.send().await()
			} catch RequestError.communicationError(let error) {
				print("Communication error whilst clearing request \(request.method) from backlog: \(error.localizedFailureReason)")
				dump(error)
				throw RequestError.communicationError(error)
			} catch {
				print("Error occurred whilst clearing request \(request.method) from backlog; ignoring: \(error.localizedFailureReason)")
				dump(error)
			}
			backlog.removeFirst()
		}
	}
	
	private func startTask<R: Request>(for request: R) -> Future<TaskResult> {
		return Future { try urlRequest(body: request) }
			.flatMap(send)
	}
	
	private func extractData<R: Request>(from taskResult: TaskResult, for request: R) throws -> R.ExpectedResponse {
		let (data, response) = taskResult
		print("\(request.method): status code: \(response.statusCode), body: \(debugRepresentation(of: data))")
		
		let metadata = try responseDecoder.decode(JSend.Metadata.self, from: data)
		guard Client.apiVersion >= metadata.version else {
			throw RequestError.outdatedClient(client: Client.apiVersion, server: metadata.version)
		}
		
		switch response.statusCode {
		case 200:
			return try request.decode(from: data, using: responseDecoder)
		case 400:
			let failure = try responseDecoder.decode(JSend.Failure.self, from: data)
			throw RequestError.apiError(failure)
		case 500:
			let error = try responseDecoder.decode(JSend.Error.self, from: data)
			throw RequestError.serverError(error)
		case let code:
			fatalError("Invalid status code \(code)")
		}
	} 
	
	private func urlRequest<R: Request>(body: R) throws -> URLRequest {
		return try URLRequest(url: apiURL(for: body)) <- { request in
			request.httpMethod = "POST"
			try body.encode(using: requestEncoder, into: &request)
		}
	}
	
	private func apiURL<R: Request>(for request: R) -> URL {
		let usernameDomain = request.username.components(separatedBy: "@").last
		let domain = usernameDomain.flatMap { domainOverrides[$0] } ?? fallbackDomain
		return domain.appendingPathComponent("api/external/\(request.method)")
	}
	
	private func send(_ request: URLRequest) -> Future<TaskResult> {
		let path = request.url!.relativePath
		print("\(path): sending \(debugRepresentation(of: request.httpBody!))")
		return urlSession.dataTask(with: request)
			.transformError { _, error in throw RequestError.communicationError(error) }
			.always { print("\(path): finished") }
	}
}

/// An error that occurs while interfacing with the server.
enum RequestError: Error {
	/// You tried to do something that requires authentication without being authenticated.
	case notAuthenticated
	/// An error occurred during communication with the server. Likely causes include an unstable internet connection and the server being down.
	case communicationError(Error)
	/// The server didn't fulfill the request because something was wrong with it.
	case apiError(JSend.Failure)
	/// The server encountered an error whilst fulfilling the request.
	case serverError(JSend.Error)
	/// The client is outdated, so we'd rather not risk further communication.
	case outdatedClient(client: Int, server: Int)
}

fileprivate func debugRepresentation(of data: Data, maxLength: Int = 1000) -> String {
	guard data.count <= maxLength else { return "<\(data.count) bytes>" }
	
	return String(bytes: data, encoding: .utf8)?
		.replacingOccurrences(of: "\n", with: "\\n")
		.replacingOccurrences(of: "\r", with: "\\r")
		?? "<\(data.count) bytes not UTF-8 decodable data>"
}

// MARK: -
// MARK: Saving & Loading

extension Client {
	func loadShared() {
		do {
			user = try defaults.decode(forKey: "Client.shared.user")
			storage = try defaults.decode(forKey: "Client.shared.storage") ?? storage
			backlog = try defaults.decode(forKey: "Client.shared.backlog") ?? backlog
			print("Client loaded!")
		} catch {
			print("Client could not be loaded!")
			print(error.localizedFailureReason)
			print(error)
		}
	}
	
	func saveShared() {
		savingQueue.async { [user, storage] in
			do {
				try defaults.encode(user, forKey: "Client.shared.user")
				try defaults.encode(storage, forKey: "Client.shared.storage")
				try self.saveBacklog()
				print("Client saved!")
			} catch {
				print("Client could not be saved!")
				print(error.localizedFailureReason)
				print(error)
			}
		}
	}
	
	// more lightweight variant of saveShared()
	func saveBacklog() throws {
		try defaults.encode(backlog, forKey: "Client.shared.backlog")
	}
}
