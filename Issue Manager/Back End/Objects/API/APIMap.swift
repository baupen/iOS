// Created by Julian Dunskus

import Foundation

struct APIMap {
	let name: String
	let parent: Map.ID?
	let fileUrl: File<Map>?
	
	func makeObject(meta: Map.Meta, context: ConstructionSite.ID) -> Map {
		Map(
			meta: meta, constructionSiteID: context,
			name: name,
			file: fileUrl,
			parentID: parent
		)
	}
}

extension APIMap: APIModel {}
