// Created by Julian Dunskus

import Foundation

final class Storage: Codable {
	private(set) var craftsmen: [UUID: Craftsman] = [:]
	private(set) var buildings: [UUID: Building] = [:]
	private(set) var maps: [UUID: Map] = [:]
	// try not to mutate these directly
	internal(set) var issues: [UUID: Issue] = [:]
	
	private var fileContainers: [FileContainer] {
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
		
		downloadMissingFiles()
	}
	
	func downloadMissingFiles() {
		fileContainers.forEach { $0.downloadFile() }
	}
	
	// somewhat defensive coding to avoid crashes when new data is read at unfortunate times
	
	func add(_ issue: Issue) {
		assert(issues[issue.id] == nil)
		
		issues[issue.id] = issue
		Client.shared.issueCreated(issue)
		
		Client.shared.saveShared()
	}
	
	func changeIssue(withID id: UUID, transform: (inout Issue) throws -> Void) rethrows {
		guard var issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		assert(!issue.isRegistered)
		
		let oldFilename = issue.filename
		try transform(&issue)
		issues[id] = issue
		Client.shared.issueChanged(issue, hasChangedFilename: issue.filename != oldFilename)
		
		Client.shared.saveShared()
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
		
		Client.shared.saveShared()
	}
	
	func markIssue(withID id: UUID) {
		guard let issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		
		issues[issue.id]!.isMarked.toggle()
		Client.shared.performed(.mark, on: issue)
		
		Client.shared.saveShared()
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
		
		Client.shared.saveShared()
	}
	
	func revertReviewForIssue(withID id: UUID) {
		guard let issue = issues[id] else {
			assertionFailure("issue must exist")
			return
		}
		assert(issue.isReviewed)
		
		issues[id]!.status.review = nil
		Client.shared.performed(.revert, on: issue)
		
		Client.shared.saveShared()
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
		
		Client.shared.saveShared()
	}
}

extension Bool {
	mutating func toggle() { // TODO remove in Swift 4.2
		self = !self
	}
}
