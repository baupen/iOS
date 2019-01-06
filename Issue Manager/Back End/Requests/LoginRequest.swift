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
		let request = LoginRequest(
			username: username,
			passwordHash: password.sha256()
		)
		return Client.shared.send(request).ignoringResult()
	}
}
