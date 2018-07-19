// Created by Julian Dunskus

import Foundation

typealias TaskResult = (data: Data, response: HTTPURLResponse)

final class Client {
	static let shared = Client()
	
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
	
	private let baseURL = URL(string: "https://dev.app.mangel.io/api/external")!
	
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
	
	private func startTask<R: Request>(for request: R) -> Future<TaskResult> {
		return Future { try urlRequest(body: request) }
			.flatMap(send)
	}
	
	private func dispatch<R: Request>(_ request: R) -> Future<TaskResult> {
		if R.isIndependent {
			return startTask(for: request)
		} else {
			return Future(asyncOn: linearQueue) {
				do {
					try self.clearBacklog()
					return try self.startTask(for: request).await()
				} catch RequestError.communicationError(let error) {
					print("Communication error during request \(request.method): \(error.localizedDescription)")
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
		while let request = backlog.first {
			do {
				try request.send().await()
			} catch RequestError.communicationError(let error) {
				print("Communication error whilst clearing request \(request.method) from backlog: \(error.localizedDescription)")
				dump(error)
				throw RequestError.communicationError(error)
			} catch {
				print("Error occurred whilst clearing request \(request.method) from backlog; ignoring: \(error.localizedDescription)")
				dump(error)
			}
			backlog.removeFirst()
		}
	}
	
	private func extractData<R: Request>(from taskResult: TaskResult, for request: R) throws -> R.ExpectedResponse {
		let (data, response) = taskResult
		print("\(request.method): status code: \(response.statusCode), body: \(debugRepresentation(of: data))")
		switch response.statusCode {
		case 200:
			return try request.decode(from: data, using: responseDecoder)
		case 400:
			let failure = try responseDecoder.decode(JSendFailure.self, from: data)
			throw RequestError.apiError(failure)
		case 500:
			let error = try responseDecoder.decode(JSendError.self, from: data)
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
		return baseURL.appendingPathComponent(request.method)
	}
	
	private func send(_ request: URLRequest) -> Future<TaskResult> {
		let path = request.url!.relativePath
		print("\(path): sending \(debugRepresentation(of: request.httpBody!))")
		return urlSession.dataTask(with: request)
			.mapError(RequestError.communicationError)
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
	case apiError(JSendFailure)
	/// The server encountered an error whilst fulfilling the request.
	case serverError(JSendError)
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
			print(error.localizedDescription)
			print(error)
		}
	}
	
	func saveShared() {
		savingQueue.async {
			do {
				try defaults.encode(self.user, forKey: "Client.shared.user")
				try defaults.encode(self.storage, forKey: "Client.shared.storage")
				try self.saveBacklog()
				print("Client saved!")
			} catch {
				print("Client could not be saved!")
				print(error.localizedDescription)
				print(error)
			}
		}
	}
	
	// more lightweight variant of saveShared()
	func saveBacklog() throws {
		try defaults.encode(backlog, forKey: "Client.shared.backlog")
	}
}
