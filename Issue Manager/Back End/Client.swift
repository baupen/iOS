// Created by Julian Dunskus

import Foundation
import UserDefault
import HandyOperators

typealias TaskResult = (data: Data, response: HTTPURLResponse)

@MainActor
final class Client {
	nonisolated static let shared = Client()
	nonisolated static let dateFormatter = ISO8601DateFormatter()
	
	@UserDefault("client.loginInfo") var loginInfo: LoginInfo?
	
	/// the user we're currently logged in as
	@UserDefault("client.localUser") var localUser: ConstructionManager?
	
	var isLoggedIn: Bool { loginInfo != nil && localUser != nil }
	
	private nonisolated init() {}
	
	func wipeAllData() {
		loginInfo = nil
		localUser = nil
	}
	
	@discardableResult
	func updateLocalUser() -> ConstructionManager? {
		localUser.flatMap { Repository.object($0.id) } 
			<- { localUser = $0 }
	}
	
	/// Provides a context for performing authenticated requests.
	///
	/// - Note: This is a method (not a property) to encourage reusing it when important, since the `await` that would usually notify of the main actor hop is already expected for the `send` that usually follows.
	/// If you're not on the main actor, getting this context cannot be done synchronously and would thus silently introduce a main actor hop with every `await client.send(...)`.
	func makeContext() -> RequestContext {
		.init(client: self, loginInfo: loginInfo)
	}
}

struct RequestContext: Sendable {
	let client: Client
	let loginInfo: LoginInfo?
	
	func send<R: Request>(_ request: R) async throws -> R.Response {
		let rawRequest = try urlRequest(for: request)
		
		let bodyDesc = rawRequest.httpBody
			.map { "\"\(debugRepresentation(of: $0))\"" }
		?? "request without body"
		print("\(request.path): \(rawRequest.httpMethod!)ing \(bodyDesc) to \(rawRequest.url!)")
		
		do {
			let rawResponse = try await send(rawRequest)
			return try extractData(from: rawResponse, for: request)
		} catch {
			print("\(request.path): failed!")
			throw error
		}
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
	
	private func urlRequest<R: Request>(for request: R) throws -> URLRequest {
		try URLRequest(url: apiURL(for: request)) <- { rawRequest in
			rawRequest.httpMethod = R.httpMethod
			try request.encode(using: requestEncoder, into: &rawRequest)
			if let token = loginInfo?.token {
				rawRequest.setValue(token, forHTTPHeaderField: "X-Authentication")
			}
			if let contentType = R.contentType {
				rawRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
			}
		}
	}
	
	private func apiURL<R: Request>(for request: R) -> URL {
		(URLComponents(
			url: request.baseURLOverride ?? loginInfo?.origin ?? baseServerURL,
			resolvingAgainstBaseURL: false
		)! <- {
			$0.percentEncodedPath += request.path
			$0.queryItems = request.collectURLQueryItems()
				.map { URLQueryItem(name: $0, value: "\($1)") }
				.nonEmptyOptional
		}).url!
	}
	
	private func send(_ request: URLRequest) async throws -> TaskResult {
		do {
			let (data, response) = try await urlSession.data(for: request)
			return (data, response as! HTTPURLResponse)
		} catch {
			throw RequestError.communicationError(error)
		}
	}
}

private let requestEncoder = JSONEncoder() <- {
	$0.dateEncodingStrategy = .iso8601
}
private let responseDecoder = JSONDecoder() <- {
	$0.dateDecodingStrategy = .iso8601
}
private let urlSession = URLSession.shared
private let baseServerURL = URL(string: "https://app.baupen.ch")!

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
	/// The client was unable to push local changes. This should succeed before any remote changes are pulled.
	case pushFailed([IssuePushError])
	/// The client is outdated, so we'd rather not risk further communication.
	// TODO: reimplement outdated client logic
}

fileprivate func debugRepresentation(of data: Data, maxLength: Int = 5000) -> String {
	guard data.count <= maxLength else { return "<\(data.count) bytes>" }
	
	return String(bytes: data, encoding: .utf8)?
		.replacingOccurrences(of: "\n", with: "\\n")
		.replacingOccurrences(of: "\r", with: "\\r")
		?? "<\(data.count) bytes not UTF-8 decodable data>"
}

extension LoginInfo: DefaultsValueConvertible {}
extension ConstructionManager: DefaultsValueConvertible {}
