// Created by Julian Dunskus

import Foundation

struct DBMap {
	let id: UUID
	let lastChangeTime: Date
	
	let children: [ID<Map>]
	let sectors: [Map.Sector]
	let sectorFrame: Rectangle?
	let issues: [ID<Issue>]
	let file: File?
	let name: String
	let constructionSiteID: ID<ConstructionSite>
}

extension DBMap: Codable {}

extension DBMap: DBModel {
	func makeObject() -> Map {
		return .init(
			meta: meta,
			children: children,
			sectors: sectors,
			sectorFrame: sectorFrame,
			issues: issues,
			file: file,
			name: name,
			constructionSiteID: constructionSiteID
		)
	}
}

extension Map: DBModelable {
	func makeModel() -> DBMap {
		return .init(
			id: rawID,
			lastChangeTime: meta.lastChangeTime,
			children: children,
			sectors: sectors,
			sectorFrame: sectorFrame,
			issues: issues,
			file: file,
			name: name,
			constructionSiteID: constructionSiteID
		)
	}
}
