// Created by Julian Dunskus

import Foundation
import Promise

typealias TaskResult = (data: Data, response: HTTPURLResponse)

final class Client {
	static let shared = Client()
	static let apiVersion = 1
	
	/// the user we're currently logged in as
	var localUser: LocalUser? {
		didSet {
			guard let localUser = localUser else { return }
			if let old = oldValue, localUser.user.id != old.user.id {
				storage = Storage() // invalidate after switching user
			}
		}
	}
	
	/// base URL for the server to contact
	var serverURL = URL(string: "https://app.mangel.io")!
	
	/// current local representation of all the data
	var storage = Storage()
	
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
			.map { response in // map instead of then, to avoid data races
				assert(OperationQueue.current!.underlyingQueue == DispatchQueue.main)
				request.applyToClient(response)
				return response
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
				error.printDetails(context: "Communication error whilst clearing request \(request.method) from backlog:")
				throw RequestError.communicationError(error)
			} catch {
				error.printDetails(context: "Error occurred whilst clearing request \(request.method) from backlog; ignoring:")
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
		
		if let metadata = try? responseDecoder.decode(JSend.Metadata.self, from: data) {
			guard Client.apiVersion >= metadata.version else {
				throw RequestError.outdatedClient(client: Client.apiVersion, server: metadata.version)
			}
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
			print("Invalid status code \(code)")
			throw RequestError.unknownError(statusCode: code)
		}
	} 
	
	private func urlRequest<R: Request>(body: R) throws -> URLRequest {
		return try URLRequest(url: apiURL(for: body)) <- { request in
			request.httpMethod = R.httpMethod
			try body.encode(using: requestEncoder, into: &request)
		}
	}
	
	private func apiURL<R: Request>(for request: R) -> URL {
		return (R.baseURLOverride ?? serverURL).appendingPathComponent("api/external/\(request.method)")
	}
	
	func send(_ request: URLRequest) -> Future<TaskResult> {
		let path = request.url!.relativePath
		print("\(path): sending \(debugRepresentation(of: request.httpBody ?? Data()))")
		return urlSession.dataTask(with: request)
			.transformError { _, error in throw RequestError.communicationError(error) }
			.always { print("\(path): finished") }
	}
}

/// An error that occurs while interfacing with the server.
enum RequestError: Error {
	/// That username can't possibly be a valid username, so we can't know which server to interface with.
	case invalidUsername
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
	/// An unknown error occurred, resulting in a nonstandard status code without a nice JSend response.
	case unknownError(statusCode: Int)
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
			localUser = try defaults.decode(forKey: "Client.shared.localUser")
			storage = try defaults.decode(forKey: "Client.shared.storage") ?? storage
			backlog = try defaults.decode(forKey: "Client.shared.backlog") ?? backlog
			serverURL = defaults.url(forKey: "Client.shared.serverURL") ?? serverURL
			print("Client loaded!")
		} catch {
			error.printDetails(context: "Client could not be loaded!")
		}
	}
	
	func saveShared() {
		savingQueue.async { [localUser, storage, serverURL] in
			do {
				try defaults.encode(localUser, forKey: "Client.shared.localUser")
				try defaults.encode(storage, forKey: "Client.shared.storage")
				try self.saveBacklog()
				defaults.set(serverURL, forKey: "Client.shared.serverURL")
				print("Client saved!")
			} catch {
				error.printDetails(context: "Could not save client: \(context)")
			}
		}
	}
	
	// more lightweight variant of saveShared()
	func saveBacklog() throws {
		try defaults.encode(backlog, forKey: "Client.shared.backlog")
	}
}
