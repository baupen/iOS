// Created by Julian Dunskus

import Foundation

struct APIConstructionSite {
	let meta: ObjectMeta<ConstructionSite>
	let name: String
	let address: ConstructionSite.Address
	let image: File<ConstructionSite>?
	
	func makeObject() -> ConstructionSite {
		ConstructionSite(
			meta: meta,
			name: name,
			address: address,
			image: image
		)
	}
}

extension APIConstructionSite: APIModel {}
