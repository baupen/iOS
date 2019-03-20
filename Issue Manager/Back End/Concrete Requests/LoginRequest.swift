// Created by Julian Dunskus

import Foundation
import Promise

struct LoginRequest: JSONJSONRequest {
	static let isIndependent = true
	
	var method: String { return "login" }
	
	let localUsername: String
	let username: String
	let passwordHash: String
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.localUser = LocalUser(
			user: response.user,
			localUsername: localUsername,
			username: username,
			passwordHash: passwordHash
		)
	}
	
	struct ExpectedResponse: Response {
		let user: User
	}
	
	enum CodingKeys: CodingKey {
		case username
		case passwordHash
	}
}

struct DomainOverridesRequest: GetRequest {
	static let baseURLOverride: URL? = URL(string: "https://app.mangel.io")!
	static let isIndependent = true
	
	var method: String { return "config/domain_overrides" }
	
	func decode(from data: Data, using decoder: JSONDecoder) throws -> ExpectedResponse {
		return try decoder.decode(ExpectedResponse.self, from: data)
	}
	
	struct ExpectedResponse: Response {
		let domainOverrides: [DomainOverride]
	}
}

extension Client {
	func logIn(as username: String, password: String) -> Future<Void> {
		guard let separatorIndex = username.lastIndex(of: "@") else {
			return .rejected(with: RequestError.invalidUsername)
		}
		let name = username[..<separatorIndex]
		let inputDomain = String(username[separatorIndex...].dropFirst())
		
		return send(DomainOverridesRequest()).flatMap {
			let override = $0.domainOverrides.first { $0.userInputDomain == inputDomain }
			let loginDomain = override?.userLoginDomain ?? inputDomain
			
			guard let serverURL = override?.serverURL ?? URL(string: "https://\(inputDomain)") else {
				return .rejected(with: RequestError.invalidUsername)
			}
			self.serverURL = serverURL
			
			let request = LoginRequest(
				localUsername: username,
				username: "\(name)@\(loginDomain)",
				passwordHash: password.sha256()
			)
			
			return self.send(request).ignoringResult()
		}
	}
}

struct DomainOverride: Decodable {
	var userInputDomain: String
	var serverURL: URL
	var userLoginDomain: String
}
