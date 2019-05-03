// Created by Julian Dunskus

import Foundation

struct APICraftsman {
	let meta: ObjectMeta<Craftsman>
	let name: String
	let trade: String
	
	func makeObject(changedConstructionSites: [APIConstructionSite]) -> Craftsman {
		return Craftsman(
			meta: meta,
			name: name,
			trade: trade,
			constructionSiteID: changedConstructionSites.first { $0.craftsmen.contains(id) }!.id
		)
	}
}

extension APICraftsman: APIModel {}
