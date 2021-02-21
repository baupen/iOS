// Created by Julian Dunskus

import Foundation
import GRDB

struct ConstructionSite {
	let meta: Meta
	
	let name: String
	let creationTime: Date
	let image: File<ConstructionSite>?
}

extension ConstructionSite: DBRecord {
	static let craftsmen = hasMany(Craftsman.self)
	var craftsmen: QueryInterfaceRequest<Craftsman> {
		request(for: Self.craftsmen).withoutDeleted
	}
	
	static let maps = hasMany(Map.self)
	var maps: QueryInterfaceRequest<Map> {
		request(for: Self.maps).withoutDeleted
	}
	
	static let issues = hasMany(Issue.self)
	var issues: QueryInterfaceRequest<Issue> {
		request(for: Self.issues).withoutDeleted
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		
		container[Columns.name] = name
		container[Columns.creationTime] = creationTime
		container[Columns.image] = image
	}
	
	init(row: Row) {
		meta = .init(row: row)
		
		name = row[Columns.name]
		creationTime = row[Columns.creationTime]
		image = row[Columns.image]
	}
	
	enum Columns: String, ColumnExpression {
		case name
		case creationTime
		case image
	}
}

extension ConstructionSite: StoredObject {
	static let apiType = "construction_sites"
}

extension ConstructionSite: FileContainer {
	static let pathPrefix = "constructionSite"
	var file: File<ConstructionSite>? { image }
}

extension ConstructionSite {
	var trades: QueryInterfaceRequest<String> {
		craftsmen
			.select(Craftsman.Columns.trade, as: String.self)
			.distinct()
	}
}
