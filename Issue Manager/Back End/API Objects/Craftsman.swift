// Created by Julian Dunskus

import Foundation
import GRDB

struct Craftsman: Equatable {
	var meta: ObjectMeta<Craftsman>
	var name: String
	var trade: String
	var constructionSiteID: ID<ConstructionSite>
}

extension Craftsman: APIObject {}

extension Craftsman: DBRecord {
	static let site = belongsTo(ConstructionSite.self)
	var site: QueryInterfaceRequest<ConstructionSite> {
		return request(for: Craftsman.site)
	}
	
	init(row: Row) {
		meta = ObjectMeta(row: row)
		name = row[Columns.name]
		trade = row[Columns.trade]
		constructionSiteID = .init(row[Columns.constructionSiteID])
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		container[Columns.name] = name
		container[Columns.trade] = trade
		container[Columns.constructionSiteID] = constructionSiteID.rawValue
	}
	
	enum Columns: String, CodingKey, ColumnExpression {
		case name
		case trade
		case constructionSiteID
	}
}
