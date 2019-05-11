// Created by Julian Dunskus

import Foundation

struct IssueUpdateRequest: MultipartJSONRequest, BacklogStorable {
	static let storageID = "issue update"
	
	static let isIndependent = false
	
	let method: String
	
	var authenticationToken: String
	let issue: APIIssue
	let fileURL: URL?
	
	func applyToClient(_ response: ExpectedResponse) {
		Repository.shared.save(response.issue.makeObject())
	}
	
	struct ExpectedResponse: Response {
		let issue: APIIssue
	}
}

extension Client {
	func issueCreated(_ issue: Issue) {
		let result = getUser()
			.map { user in
				IssueUpdateRequest(
					method: "issue/create",
					authenticationToken: user.authenticationToken,
					issue: issue.makeModel(),
					fileURL: issue.image.map(Issue.localURL)
				)
			}.flatMap(send)
		
		logOutcome(of: result, as: "issue creation")
	}
}

extension Client {
	func issueChanged(_ issue: Issue, hasChangedFile: Bool) {
		let result = getUser()
			.map { user in
				IssueUpdateRequest(
					method: "issue/update",
					authenticationToken: user.authenticationToken,
					issue: issue.makeModel(),
					fileURL: hasChangedFile ? issue.image.map(Issue.localURL) : nil
				)
			}.flatMap(send)
		
		logOutcome(of: result, as: "issue update")
	}
}
