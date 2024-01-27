// Created by Julian Dunskus

import Foundation

private struct SelfRequest: GetJSONRequest {
	let path = "/api/me"
	
	struct Response: Decodable {
		var constructionManagerIri: APIObjectMeta<APIConstructionManager>.ID
	}
}

extension Client {
	func logIn(with loginInfo: LoginInfo) async throws {
		self.loginInfo = loginInfo
		do {
			let context = makeContext()
			let userID = try await context.send(SelfRequest()).constructionManagerIri.makeID()
			let user = try await context.send(GetObjectRequest(for: userID)).makeObject()
			self.loginInfo = loginInfo // set again in case something else changed it since
			self.localUser = user
			Repository.shared.signedIn(as: user)
		} catch {
			self.loginInfo = nil
			throw error
		}
	}
}
