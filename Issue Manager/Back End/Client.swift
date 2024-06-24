// Created by Julian Dunskus

import Foundation
import UserDefault
import Protoquest
import HandyOperators

typealias TaskResult = (data: Data, response: HTTPURLResponse)

@MainActor
final class Client {
	nonisolated static let dateFormatter = ISO8601DateFormatter()
	
	@UserDefault("client.loginInfo") var loginInfo: LoginInfo?
	
	/// the user we're currently logged in as
	@UserDefault("client.localUser") var localUser: ConstructionManager?
	
	var isLoggedIn: Bool { loginInfo != nil && localUser != nil }
	
	private let _makeContext: @Sendable (Client, LoginInfo?) -> any RequestContext
	
	nonisolated init(
		makeContext: @escaping @Sendable (Client, LoginInfo?) -> any RequestContext = {
			DefaultRequestContext(client: $0, loginInfo: $1)
		} // can't use pointfree reference to DefaultRequestContext.init because it's not sendable
	) {
		self._makeContext = makeContext
	}
	
	func wipeAllData() {
		loginInfo = nil
		localUser = nil
	}
	
	@discardableResult
	func updateLocalUser(from repository: Repository) -> ConstructionManager? {
		localUser = localUser.flatMap { repository.object($0.id) }
		return localUser
	}
	
	/// Provides a context for performing authenticated requests.
	///
	/// - Note: This is a method (not a property) to encourage reusing it when important, since the `await` that would usually notify of the main actor hop is already expected for the `send` that usually follows.
	/// If you're not on the main actor, getting this context cannot be done synchronously and would thus silently introduce a main actor hop with every `await client.send(...)`.
	func makeContext() -> any RequestContext {
		_makeContext(self, loginInfo)
	}
}

protocol RequestContext: Sendable {
	var client: Client { get }
	var loginInfo: LoginInfo? { get }
	
	func send<R: BaupenRequest>(_ request: R) async throws -> R.Response
}

struct DefaultRequestContext: RequestContext {
	let client: Client
	let loginInfo: LoginInfo?
	
	func send<R: BaupenRequest>(_ request: R) async throws -> R.Response {
		let layer = Protolayer.urlSession(baseURL: loginInfo?.origin ?? baseServerURL)
			.wrapErrors(RequestError.communicationError(_:))
			.printExchanges()
			.transformRequest { request in
				if let token = loginInfo?.token {
					request.setValue(token, forHTTPHeaderField: "X-Authentication")
				}
			}
			.readResponse(handleErrors(in:))
		
		do {
			return try await layer.send(request)
		} catch {
			print("\(request.path): failed!")
			throw error
		}
	}
	
	private func handleErrors(in response: Protoresponse) throws {
		switch response.httpMetadata!.statusCode {
		case 200..<300:
			break // success
		case 401:
			throw RequestError.notAuthenticated
		case let statusCode:
			let hydraError: HydraError? = if
				response.contentType?.hasPrefix("application/ld+json") == true,
				let metadata = try? response.decodeJSON(as: HydraMetadata.self, using: responseDecoder),
				metadata.type == HydraError.type
			{
				try? response.decodeJSON(using: responseDecoder)
			} else { nil }
			throw RequestError.apiError(hydraError, statusCode: statusCode)
		}
	}
}

protocol BaupenRequest: Request, Sendable where Response: Sendable {}
extension BaupenRequest where Self: JSONEncodingRequest {
	var encoderOverride: JSONEncoder? { requestEncoder }
}
extension BaupenRequest where Self: MultipartEncodingRequest {
	var encoderOverride: JSONEncoder? { requestEncoder }
}
extension BaupenRequest where Self: JSONDecodingRequest {
	var decoderOverride: JSONDecoder? { responseDecoder }
}

private let requestEncoder = JSONEncoder() <- {
	$0.dateEncodingStrategy = .iso8601
}
private let responseDecoder = JSONDecoder() <- {
	$0.dateDecodingStrategy = .iso8601
}
private let baseServerURL = URL(string: "https://app.baupen.ch")!

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

extension LoginInfo: DefaultsValueConvertible {}
extension ConstructionManager: DefaultsValueConvertible {}
