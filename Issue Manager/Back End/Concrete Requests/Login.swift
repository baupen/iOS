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
			.always { print("step 1") }
			.map { GetObjectRequest(for: $0.constructionManagerIri.makeID()) }
			.flatMap(send)
			.always { print("step 2") }
			.map { self.localUser = $0.makeObject() }
	}
}
