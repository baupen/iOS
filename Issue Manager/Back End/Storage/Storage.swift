// Created by Julian Dunskus

import Foundation

final class Storage: Codable {
	typealias ObjectDictionary<T: APIObject> = [ID<T>: T]
	
	var craftsmen = ObjectDictionary<Craftsman>()
	var sites = ObjectDictionary<ConstructionSite>()
	var maps = ObjectDictionary<Map>()
	var issues = ObjectDictionary<Issue>()
	
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
	}
	
	func downloadMissingFiles() {
		fileContainers.forEach { $0.downloadFile() }
	}
}
