// Created by Julian Dunskus

import Foundation

final class Storage: Codable {
	private(set) var craftsmen: [ID<Craftsman>: Craftsman] = [:]
	private(set) var sites: [ID<ConstructionSite>: ConstructionSite] = [:]
	private(set) var maps: [ID<Map>: Map] = [:]
	// try not to mutate these from outside the backend group
	internal(set) var issues: [ID<Issue>: Issue] = [:]
	
	private var fileContainers: [AnyFileContainer] {
		return Array(sites.values) as [AnyFileContainer]
			+ Array(maps.values)
			+ Array(issues.values)
	}
	
	init() {}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		craftsmen = try container.decodeValue(forKey: .craftsmen)
		sites     = try container.decodeValue(forKey: .sites)
		maps      = try container.decodeValue(forKey: .maps)
		issues    = try container.decodeValue(forKey: .issues)
		
		// not yet; Client.shared isn't initialized yet
		DispatchQueue.global().async {
			self.downloadMissingFiles()
		}
	}
	
	func downloadMissingFiles() {
		fileContainers.forEach { $0.downloadFile() }
	}
	
	func add(_ issue: Issue) {
		assert(issues[issue.id] == nil)
		
		issues[issue.id] = issue
		maps[issue.map]!.issues.append(issue.id)
		Client.shared.issueCreated(issue)
		
		Client.shared.saveShared()
	}
	
	func remove(_ issue: Issue) {
		assert(!issue.isRegistered)
		
		issues[issue.id] = nil
		issue.deleteFile()
		Client.shared.issueRemoved(issue)
		
		Client.shared.saveShared()
	}
}
