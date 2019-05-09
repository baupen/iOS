// Created by Julian Dunskus

import Foundation

struct APIConstructionSite {
	let meta: ObjectMeta<ConstructionSite>
	let name: String
	let address: ConstructionSite.Address
	let image: File<ConstructionSite>?
	let maps: [ID<Map>]
	let craftsmen: [ID<Craftsman>]
	
	func makeObject() -> ConstructionSite {
		return ConstructionSite(
			meta: meta,
			name: name,
			address: address,
			image: image
		)
	}
}

extension APIConstructionSite: APIModel {}
