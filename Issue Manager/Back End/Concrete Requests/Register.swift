// Created by Julian Dunskus

import Foundation
import Promise

private struct RegisterRequest: JSONEncodingRequest, StatusCodeRequest {
	var baseURLOverride: URL?
	var path: String { ConstructionManager.apiPath }
	
	var body: Body
	
	struct Body: Encodable {
		var email: String
	}
}

extension Client {
	func register(asEmail email: String, at domain: URL) -> Future<Void> {
		wipeAllData()
		return send(RegisterRequest(baseURLOverride: domain, body: .init(email: email)))
	}
}
