// Created by Julian Dunskus

import Foundation
import Promise

struct LoginRequest: JSONJSONRequest {
	static let isIndependent = true
	
	var method: String { return "login" }
	
	let username: String
	let passwordHash: String
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.localUser = LocalUser(
			user: response.user,
			username: username,
			passwordHash: passwordHash
		)
		Client.shared.saveShared()
	}
	
	struct ExpectedResponse: Response {
		let user: User
	}
}

extension Client {
	func logIn(as username: String, password: String) -> Future<Void> {
		guard let separatorIndex = username.lastIndex(of: "@") else {
			return .rejected(with: RequestError.invalidUsername)
		}
		let name = username[..<separatorIndex]
		let domain = String(username[separatorIndex...].dropFirst())
		
		let override = domainOverrides[domain]
		let newDomain = override?.domain ?? domain
		
		guard let serverURL = override?.url ?? URL(string: "https://\(domain)") else {
			return .rejected(with: RequestError.invalidUsername)
		}
		self.serverURL = serverURL
		
		let request = LoginRequest(
			username: "\(name)@\(newDomain)",
			passwordHash: password.sha256()
		)
		
		return Client.shared.send(request).ignoringResult()
	}
}

struct DomainOverride: Decodable {
	var url: URL
	var domain: String
}

fileprivate let domainOverrides: [String: DomainOverride] = {
	let path = Bundle.main.path(forResource: "domains.private", ofType: "json")!
	do {
		let raw = try Data(contentsOf: URL(fileURLWithPath: path))
		return try JSONDecoder().decode(from: raw)
	} catch {
		print("Could not load domain overrides!", error.localizedFailureReason)
		dump(error)
		return [:]
	}
}()
