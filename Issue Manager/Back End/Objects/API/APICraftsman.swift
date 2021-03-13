// Created by Julian Dunskus

import Foundation

struct APICraftsman {
	let contactName: String
	let company: String
	let trade: String
	
	func makeObject(meta: Craftsman.Meta, context: ConstructionSite.ID) -> Craftsman {
		Craftsman(
			meta: meta, constructionSiteID: context,
			contactName: contactName,
			company: company,
			trade: trade
		)
	}
}

extension APICraftsman: APIModel {}
