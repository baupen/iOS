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
	
	var method: String { "issue/\(action.rawValue)" }
	
	var authenticationToken: String
	let issueID: ID<Issue>
	let action: IssueAction
	
	func applyToClient(_ response: ExpectedResponse) {
		Repository.shared.save(response.issue.makeObject())
	}
	
	struct ExpectedResponse: Response {
		let issue: APIIssue
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
			}.flatMap(send)
		
		logOutcome(of: result, as: "issue \(action.rawValue)")
	}
}
