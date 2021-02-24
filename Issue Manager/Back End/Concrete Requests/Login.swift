// Created by Julian Dunskus

import Foundation
import Promise

private struct SelfRequest: GetJSONRequest {
	let path = "/api/me"
	
	let token: String
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {
		request.setValue(token, forHTTPHeaderField: "X-Authentication")
	}
	
	struct Response: Decodable {
		var constructionManagerIri: APIObjectMeta<APIConstructionManager>.ID
	}
}

extension Client {
	func logIn(with loginInfo: LoginInfo) -> Future<Void> {
		self.loginInfo = loginInfo
		return send(SelfRequest(token: loginInfo.token))
			.map { GetObjectRequest(for: $0.constructionManagerIri.makeID()) }
			.flatMap(send)
			.map {
				self.loginInfo = loginInfo // set again in case something else changed it since
				self.localUser = $0.makeObject()
			}
			.catch { _ in
				self.loginInfo = nil
			}
	}
}
