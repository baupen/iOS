// Created by Julian Dunskus

import Foundation

struct DBConstructionSite {
	let id: UUID
	let lastChangeTime: Date
	
	let name: String
	let address: ConstructionSite.Address
	let image: File?
	let maps: [ID<Map>]
	let craftsmen: [ID<Craftsman>]
}

extension DBConstructionSite: Codable {}

extension DBConstructionSite: DBModel {
	func makeObject() -> ConstructionSite {
		return .init(
			meta: meta,
			name: name,
			address: address,
			image: image,
			maps: maps,
			craftsmen: craftsmen
		)
	}
}

extension ConstructionSite: DBModelable {
	func makeModel() -> DBConstructionSite {
		return .init(
			id: rawID,
			lastChangeTime: meta.lastChangeTime,
			name: name,
			address: address,
			image: image,
			maps: maps,
			craftsmen: craftsmen
		)
	}
}
