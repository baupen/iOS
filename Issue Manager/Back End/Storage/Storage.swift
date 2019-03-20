// Created by Julian Dunskus

import Foundation

final class Storage: Codable {
	typealias ObjectDictionary<T: APIObject> = [ID<T>: T]
	
	var craftsmen = ObjectDictionary<Craftsman>()
	var sites = ObjectDictionary<ConstructionSite>()
	var maps = ObjectDictionary<Map>()
	var issues = ObjectDictionary<Issue>()
	
	init() {}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		craftsmen = try container.decodeValue(forKey: .craftsmen)
		sites     = try container.decodeValue(forKey: .sites)
		maps      = try container.decodeValue(forKey: .maps)
		issues    = try container.decodeValue(forKey: .issues)
	}
	
	func downloadMissingFiles() {
		sites.values.forEach { $0.downloadFile() }
		maps.values.forEach { $0.downloadFile() }
		issues.values.forEach { $0.downloadFile() }
	}
}
