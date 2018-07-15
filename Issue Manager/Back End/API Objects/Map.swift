// Created by Julian Dunskus

import Foundation

final class Map: MapHolder, FileContainer {
	let meta: ObjectMeta
	let children: [UUID]
	var issues: [UUID]
	let filename: String?
	let name: String
	
	var buildingID: UUID!
	
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
	
	enum CodingKeys: CodingKey {
		case meta
		case children
		case issues
		case filename
		case name
	}
}

extension Map {
	func recursiveChildren() -> [Map] {
		return [self] + childMaps().flatMap { $0.recursiveChildren() }
	}
	
	func allIssues() -> AnyCollection<Issue> {
		return AnyCollection(issues.lazy.compactMap { Client.shared.storage.issues[$0] })
	}
	
	func accessBuilding() -> Building {
		return Client.shared.storage.buildings[buildingID]!
	}
}
