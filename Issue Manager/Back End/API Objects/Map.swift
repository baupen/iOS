// Created by Julian Dunskus

import Foundation

final class Map: APIObject {
	let meta: ObjectMeta
	let children: [UUID]
	var issues: [UUID]
	let filename: String?
	let name: String
	let buildingID: UUID
}

extension Map: FileContainer {
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
}

extension Map: MapHolder {
	func recursiveChildren() -> [Map] {
		return [self] + childMaps().flatMap { $0.recursiveChildren() }
	}
}

extension Map {
	func allIssues() -> AnyCollection<Issue> {
		return AnyCollection(issues.lazy.compactMap { Client.shared.storage.issues[$0] })
	}
	
	func accessBuilding() -> Building {
		return Client.shared.storage.buildings[buildingID]!
	}
}
