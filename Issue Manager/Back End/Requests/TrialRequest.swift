// Created by Julian Dunskus

import Foundation
import Promise

struct CreateTrialAccountRequest: JSONJSONRequest {
	static let isIndependent = true
	
	var method: String { return "trial/create_account" }
	
	let proposedGivenName: String?
	let proposedFamilyName: String?
	
	struct ExpectedResponse: Response {
		let trialUser: TrialUser
	}
}

extension Client {
	func createTrialAccount(proposedGivenName: String?, proposedFamilyName: String?) -> Future<TrialUser> {
		let request = CreateTrialAccountRequest(
			proposedGivenName: proposedGivenName,
			proposedFamilyName: proposedFamilyName
		)
		return Client.shared.send(request).map { $0.trialUser }
	}
}


