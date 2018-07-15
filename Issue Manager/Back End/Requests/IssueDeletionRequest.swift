// Created by Julian Dunskus

import Foundation

struct IssueDeletionRequest: JSONJSONRequest, BacklogStorable {
	static let storageID = "issue deletion"
	
	static let isIndependent = false
	
	var method: String { return "issue/delete" }
	
	let authenticationToken: String
	let issueID: UUID
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.storage.issues[issueID]?.deleteFile()
		Client.shared.storage.issues[issueID] = nil
		Client.shared.saveShared()
	}
	
	struct ExpectedResponse: Response {}
}

extension Client {
	func issueRemoved(_ issue: Issue) {
		let result = getUser()
			.map { user in
				IssueDeletionRequest(
					authenticationToken: user.authenticationToken,
					issueID: issue.id
				)
			}.flatMap(Client.shared.send)
		
		logOutcome(of: result, as: "issue deletion")
	}
}
