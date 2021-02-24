// Created by Julian Dunskus

import Foundation

struct APIConstructionSite {
	let name: String
	let createdAt: Date
	let imageUrl: File<ConstructionSite>?
	let constructionManagers: [APIConstructionManager.ID]
	
	func makeObject(meta: ConstructionSite.Meta, context: Void) -> ConstructionSite {
		ConstructionSite(
			meta: meta,
			name: name,
			creationTime: createdAt,
			image: imageUrl,
			managers: .init(constructionManagers.map { $0.makeID() })
		)
	}
}

extension APIConstructionSite: APIModel {}
