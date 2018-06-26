// Created by Julian Dunskus

import Foundation

struct Storage: Codable {
	var craftsmen: [UUID: Craftsman] = [:]
	var buildings: [UUID: Building] = [:]
	var maps: [UUID: Map] = [:]
	var issues: [UUID: Issue] = [:]
	
	var fileContainers: [FileContainer] {
		return Array(buildings.values) as [FileContainer]
			+ Array(maps.values)
			+ Array(issues.values)
	}
	
	init() {}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		craftsmen = try container.decodeValue(forKey: .craftsmen)
		buildings = try container.decodeValue(forKey: .buildings)
		maps      = try container.decodeValue(forKey: .maps)
		issues    = try container.decodeValue(forKey: .issues)
	}
}
