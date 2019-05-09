// Created by Julian Dunskus

import Foundation

struct APIMap {
	let meta: ObjectMeta<Map>
	let children: [ID<Map>]
	let sectors: [Map.Sector]
	let sectorFrame: Rectangle?
	let issues: [ID<Issue>]
	let file: File<Map>?
	let name: String
	let constructionSiteID: ID<ConstructionSite>
	
	func makeObject(changedMaps: [APIMap]) -> Map {
		return Map(
			meta: meta,
			sectors: sectors,
			sectorFrame: sectorFrame,
			file: file,
			name: name,
			constructionSiteID: constructionSiteID,
			parentID: changedMaps.first { $0.children.contains(id) }?.id
		)
	}
}

extension APIMap: APIModel {}
