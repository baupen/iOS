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
	let parentID: ID<Map>?
	
	func makeObject(changedMaps: [APIMap]) -> Map {
		return Map(
			meta: meta,
			sectors: sectors,
			sectorFrame: sectorFrame,
			file: file,
			name: name,
			constructionSiteID: constructionSiteID,
			parentID: parentID
		)
	}
}

extension APIMap: APIModel {}
