// Created by Julian Dunskus

import Foundation
import Promise

struct LoginRequest: JSONJSONRequest {
	static let isIndependent = true
	
	var method: String { "login" }
	
	let serverURL: URL
	let username: String
	let passwordHash: String
	
	var baseURLOverride: URL? { serverURL }
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.serverURL = serverURL
		Client.shared.localUser = LocalUser(
			user: response.user,
			username: username,
			passwordHash: passwordHash
		)
	}
	
	struct ExpectedResponse: Response {
		let user: User
	}
	
	private enum CodingKeys: CodingKey {
		case username
		case passwordHash
	}
}

struct DomainOverridesRequest: GetRequest {
	static let isIndependent = true
	
	let baseURLOverride: URL? = URL(string: "https://app.mangel.io")!
	var method: String { "config/domain_overrides" }
	
	func decode(from data: Data, using decoder: JSONDecoder) throws -> ExpectedResponse {
		try decoder.decode(ExpectedResponse.self, from: data)
	}
	
	struct ExpectedResponse: Response {
		let domainOverrides: [DomainOverride]
	}
	
	private enum CodingKeys: CodingKey {}
}

extension Client {
	func getDomainOverrides() -> Future<[DomainOverride]> {
		send(DomainOverridesRequest()).map { $0.domainOverrides }
	}
	
	func logIn(to serverURL: URL, as username: String, password: String) -> Future<Void> {
		let request = LoginRequest(
			serverURL: serverURL,
			username: username,
			passwordHash: password.sha256()
		)
		
		return self.send(request).ignoringResult()
	}
}

struct Username {
	var name: String
	var domain: String
	
	var raw: String {
		"\(name)@\(domain)"
	}
	
	init?(_ raw: String) {
		guard let separatorIndex = raw.lastIndex(of: "@") else { return nil }
		name = String(raw[..<separatorIndex])
		domain = String(raw[separatorIndex...].dropFirst())
	}
}

struct DomainOverride: Decodable {
	var userInputDomain: String
	var serverURL: URL
	var userLoginDomain: String
	
	func applied(to username: Username) -> (serverURL: URL, username: Username)? {
		guard userInputDomain == username.domain else { return nil }
		return (serverURL, username <- { $0.domain = userLoginDomain })
	}
}

extension Sequence where Element == DomainOverride {
	func firstMatch(for username: Username) -> (serverURL: URL, username: Username)? {
		lazy.compactMap { $0.applied(to: username) }.first
	}
}
