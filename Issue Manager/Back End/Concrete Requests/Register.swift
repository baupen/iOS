// Created by Julian Dunskus

import Foundation

private struct RegisterRequest: JSONEncodingRequest, StatusCodeRequest {
	var baseURLOverride: URL?
	var path: String { ConstructionManager.apiPath }
	
	var body: Body
	
	struct Body: Encodable {
		var email: String
	}
}

extension Client {
	func register(asEmail email: String, at domain: URL) async throws {
		wipeAllData()
		return try await makeContext().send(RegisterRequest(baseURLOverride: domain, body: .init(email: email)))
	}
}
