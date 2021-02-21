// Created by Julian Dunskus

import Foundation
import Promise

typealias TaskResult = (data: Data, response: HTTPURLResponse)

final class Client {
	static let shared = Client()
	static let apiVersion = 1
	static let dateFormatter = ISO8601DateFormatter()
	
	/// the user we're currently logged in as
	var localUser: LocalUser? {
		didSet {
			saveLocalUser()
			guard let localUser = localUser else { return }
			if let old = oldValue, localUser.id != old.id {
				Repository.shared.resetAllData()
			}
		}
	}
	
	/// base URL for the server to contact
	var serverURL = URL(string: "https://app.mangel.io")! {
		didSet { saveServerURL() }
	}
	
	private let urlSession = URLSession.shared
	
	private let requestEncoder = JSONEncoder() <- {
		$0.dateEncodingStrategy = .iso8601
	}
	private let responseDecoder = JSONDecoder() <- {
		$0.dateDecodingStrategy = .iso8601
	}
	
	/// any dependent requests are executed on this queue, so as to avoid bad interleavings and races and such
	private let linearQueue = DispatchQueue(label: "dependent request execution")
	
	var isOnLinearQueue: Bool {
		OperationQueue.current!.underlyingQueue == linearQueue
	}
	
	private init() {
		loadShared()
	}
	
	func send<R: Request>(_ request: R) -> Future<R.Response> {
		dispatch(request)
			.map { taskResult in try self.extractData(from: taskResult, for: request) }
	}
	
	private func dispatch<R: Request>(_ request: R) -> Future<TaskResult> {
		startTask(for: request)
	}
	
	func pushChangesThen<T>(perform task: @escaping () throws -> T) -> Future<T> {
		Future(asyncOn: linearQueue) {
			try self.synchronouslyPushLocalChanges()
			return try task()
		}
	}
	
	private func startTask<R: Request>(for request: R) -> Future<TaskResult> {
		Future { try urlRequest(body: request) }
			.flatMap(send)
	}
	
	private func extractData<R: Request>(from taskResult: TaskResult, for request: R) throws -> R.Response {
		let (data, response) = taskResult
		print("\(request.path): status code: \(response.statusCode), body: \(debugRepresentation(of: data))")
		
		switch response.statusCode {
		case 200..<300:
			return try request.decode(from: data, using: responseDecoder)
		case 401:
			throw RequestError.notAuthenticated
		case let statusCode:
			var hydraError: HydraError?
			if
				response.contentType?.hasPrefix("application/ld+json") == true,
				let metadata = try? responseDecoder.decode(HydraMetadata.self, from: data),
				metadata.type == HydraError.type
			{
				hydraError = try? responseDecoder.decode(from: data)
			}
			throw RequestError.apiError(hydraError, statusCode: statusCode)
		}
	}
	
	private func urlRequest<R: Request>(body: R) throws -> URLRequest {
		try URLRequest(url: apiURL(for: body)) <- { request in
			request.httpMethod = R.httpMethod
			try body.encode(using: requestEncoder, into: &request)
		}
	}
	
	private func apiURL<R: Request>(for request: R) -> URL {
		(URLComponents(url: request.baseURLOverride ?? serverURL, resolvingAgainstBaseURL: false)! <- {
			$0.path += request.path
			$0.queryItems = request.collectURLQueryItems()
				.map { URLQueryItem(name: $0, value: "\($1)") }
		}).url!
	}
	
	func send(_ request: URLRequest) -> Future<TaskResult> {
		let path = request.url!.relativePath
		print("\(path): sending \(debugRepresentation(of: request.httpBody ?? Data()))")
		return urlSession.dataTask(with: request)
			.transformError { _, error in throw RequestError.communicationError(error) }
			.always { print("\(path): finished") }
	}
}

extension HTTPURLResponse {
	var contentType: String? {
		allHeaderFields["Content-Type"] as? String
	}
}

/// An error that occurs while interfacing with the server.
enum RequestError: Error {
	/// You tried to do something that requires authentication without being authenticated.
	case notAuthenticated
	/// An error occurred during communication with the server. Likely causes include an unstable internet connection and the server being down.
	case communicationError(Error)
	/// There was an error fulfilling the request.
	case apiError(HydraError? = nil, statusCode: Int)
	/// The client is outdated, so we'd rather not risk further communication.
	case outdatedClient(client: Int, server: Int) // TODO: reimplement
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

private extension Client {
	func loadShared() {
		do {
			// TODO: remove once most users have migrated to database
			defaults.removeObject(forKey: "Client.shared.storage")
			
			localUser = try defaults.decode(forKey: .localUserKey)
			serverURL = defaults.url(forKey: .serverURLKey) ?? serverURL
			print("Client loaded!")
		} catch {
			error.printDetails(context: "Client could not be loaded!")
		}
	}
	
	func saveLocalUser() {
		save(context: "localUser") { [localUser] in
			try defaults.encode(localUser, forKey: .localUserKey)
		}
	}
	
	func saveServerURL() {
		save(context: "serverURL") { [serverURL] in
			defaults.set(serverURL, forKey: .serverURLKey)
		}
	}
	
	private func save(context: String, _ block: @escaping () throws -> Void) {
		do {
			try block()
		} catch {
			error.printDetails(context: "Could not save client: \(context)")
		}
	}
}

private extension String {
	static let localUserKey = "Client.shared.localUser"
	static let serverURLKey = "Client.shared.serverURL"
}
