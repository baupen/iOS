// Created by Julian Dunskus

import Foundation

struct APICraftsman {
	let meta: ObjectMeta<Craftsman>
	let name: String
	let trade: String
	let constructionSiteID: ID<ConstructionSite>
	
	func makeObject(changedConstructionSites: [APIConstructionSite]) -> Craftsman {
		return Craftsman(
			meta: meta,
			name: name,
			trade: trade,
			constructionSiteID: constructionSiteID
		)
	}
}

extension APICraftsman: APIModel {}
