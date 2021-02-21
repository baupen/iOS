// Created by Julian Dunskus

import Foundation

struct APIConstructionSite {
	let name: String
	let createdAt: Date
	let imageUrl: File<ConstructionSite>?
	
	func makeObject(meta: ConstructionSite.Meta, context: Void) -> ConstructionSite {
		ConstructionSite(
			meta: meta,
			name: name,
			creationTime: createdAt,
			image: imageUrl
		)
	}
}

extension APIConstructionSite: APIModel {}
