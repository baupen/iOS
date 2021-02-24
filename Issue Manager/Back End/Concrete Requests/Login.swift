// Created by Julian Dunskus

import Foundation
import Promise

private struct SelfRequest: GetJSONRequest {
	let path = "/api/me"
	
	struct Response: Decodable {
		var constructionManagerIri: APIObjectMeta<APIConstructionManager>.ID
	}
}

extension Client {
	func logIn(with loginInfo: LoginInfo) -> Future<Void> {
		self.loginInfo = loginInfo
		return send(SelfRequest())
			.map { GetObjectRequest(for: $0.constructionManagerIri.makeID()) }
			.flatMap(send)
			.map {
				self.loginInfo = loginInfo // set again in case something else changed it since
				let user = $0.makeObject()
				self.localUser = user
				Repository.shared.signedIn(as: user)
			}
			.catch { _ in
				self.loginInfo = nil
			}
	}
}
