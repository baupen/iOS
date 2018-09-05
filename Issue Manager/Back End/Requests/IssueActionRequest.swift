// Created by Julian Dunskus

import Foundation

enum IssueAction: String, Codable {
	case mark
	case review
	case revert
}

struct IssueActionRequest: JSONJSONRequest, BacklogStorable {
	static let storageID = "issue action"
	static let isIndependent = false
	
	var method: String { return "issue/\(action.rawValue)" }
	
	let authenticationToken: String
	let issueID: ID<Issue>
	let action: IssueAction
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.storage.issues[response.issue.id]?.update(from: response.issue)
		Client.shared.saveShared()
	}
	
	struct ExpectedResponse: Response {
		let issue: Issue
	}
}

extension Client {
	func performed(_ action: IssueAction, on issue: Issue) {
		let result = getUser()
			.map { user in
				IssueActionRequest(
					authenticationToken: user.authenticationToken,
					issueID: issue.id,
					action: action
				)
			}.flatMap(Client.shared.send)
		
		logOutcome(of: result, as: "issue \(action.rawValue)")
	}
}
