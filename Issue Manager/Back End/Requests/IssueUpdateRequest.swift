// Created by Julian Dunskus

import Foundation

struct IssueUpdateRequest: MultipartJSONRequest, BacklogStorable {
	static let storageID = "issue update"
	
	static let isIndependent = false
	
	let method: String
	
	let authenticationToken: String
	let issue: Issue
	let fileURL: URL?
	
	func applyToClient(_ response: ExpectedResponse) {
		issue.update(from: response.issue)
		Client.shared.saveShared()
	}
	
	struct ExpectedResponse: Response {
		let issue: Issue
	}
}

extension Client {
	func issueCreated(_ issue: Issue) {
		let result = getUser()
			.map { user in
				IssueUpdateRequest(
					method: "issue/create",
					authenticationToken: user.authenticationToken,
					issue: issue,
					fileURL: issue.filename.map(Issue.localURL)
				)
			}.flatMap(Client.shared.send)
		
		logOutcome(of: result, as: "issue creation")
	}
}

extension Client {
	func issueChanged(_ issue: Issue, hasChangedFilename: Bool) {
		let result = getUser()
			.map { user in
				IssueUpdateRequest(
					method: "issue/update",
					authenticationToken: user.authenticationToken,
					issue: issue,
					fileURL: hasChangedFilename ? issue.filename.map(Issue.localURL) : nil
				)
			}.flatMap(Client.shared.send)
		
		logOutcome(of: result, as: "issue update")
	}
}
