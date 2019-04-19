// Created by Julian Dunskus

import Foundation

struct DBCraftsman {
	let id: UUID
	let lastChangeTime: Date
	
	let name: String
	let trade: String
}

extension DBCraftsman: Codable {}

extension DBCraftsman: DBModel {
	func makeObject() -> Craftsman {
		return .init(
			meta: meta,
			name: name,
			trade: trade
		)
	}
}

extension Craftsman: DBModelable {
	func makeModel() -> DBCraftsman {
		return .init(
			id: rawID,
			lastChangeTime: meta.lastChangeTime,
			name: name,
			trade: trade
		)
	}
}
