// Created by Julian Dunskus

import Foundation

final class Storage: Codable {
	private(set) var craftsmen: [UUID: Craftsman] = [:]
	private(set) var buildings: [UUID: Building] = [:]
	private(set) var maps: [UUID: Map] = [:]
	// try not to mutate these directly
	internal(set) var issues: [UUID: Issue] = [:]
	
	var fileContainers: [FileContainer] {
		return Array(buildings.values) as [FileContainer]
			+ Array(maps.values)
			+ Array(issues.values)
	}
	
	init() {}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		craftsmen = try container.decodeValue(forKey: .craftsmen)
		buildings = try container.decodeValue(forKey: .buildings)
		maps      = try container.decodeValue(forKey: .maps)
		issues    = try container.decodeValue(forKey: .issues)
	}
	
	func add(_ issue: Issue) {
		issues[issue.id] = issue
		Client.shared.issueCreated(issue)
	}
	
	// somewhat defensive coding to avoid crashes when new data is read at unfortunate times
	
	func changeIssue(withID id: UUID, transform: (inout Issue) throws -> Void) rethrows {
		guard var issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		assert(!issue.isRegistered)
		try transform(&issue)
		issues[id] = issue
		Client.shared.issueChanged(issue)
	}
	
	func removeIssue(withID id: UUID) {
		guard let issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		assert(!issue.isRegistered)
		issues[issue.id] = nil
		issue.deleteFile()
		Client.shared.issueRemoved(issue)
	}
	
	func markIssue(withID id: UUID) {
		guard let issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		issues[issue.id]!.isMarked.toggle()
		Client.shared.performed(.mark, on: issue)
	}
	
	func reviewIssue(withID id: UUID) {
		guard let issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		assert(issue.isRegistered)
		assert(!issue.isReviewed)
		issues[id]!.status.review = .init(at: Date(), by: Client.shared.user!.fullName)
		Client.shared.performed(.review, on: issue)
	}
	
	func revertReviewForIssue(withID id: UUID) {
		guard let issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		assert(issue.isReviewed)
		issues[id]!.status.review = nil
		Client.shared.performed(.revert, on: issue)
	}
	
	func revertResponseForIssue(withID id: UUID) {
		guard let issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		assert(issue.hasResponse)
		assert(!issue.isReviewed)
		issues[id]!.status.review = nil
		Client.shared.performed(.revert, on: issue)
	}
}
