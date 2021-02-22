// Created by Julian Dunskus

import Foundation
import GRDB

struct Craftsman: Equatable {
	var meta: Meta
	var constructionSiteID: ConstructionSite.ID
	
	var contactName: String
	var company: String
	var trade: String
	
	var companyAndContact: String {
		"\(company) (\(contactName))"
	}
}

extension Craftsman: StoredObject {
	typealias Model = APICraftsman
	static let apiType = "craftsmen"
}

extension Craftsman: DBRecord {
	static let site = belongsTo(ConstructionSite.self)
	var site: QueryInterfaceRequest<ConstructionSite> {
		request(for: Self.site)
	}
	
	init(row: Row) {
		meta = ObjectMeta(row: row)
		constructionSiteID = row[Columns.constructionSiteID]
		
		contactName = row[Columns.contactName]
		company = row[Columns.company]
		trade = row[Columns.trade]
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		container[Columns.constructionSiteID] = constructionSiteID
		
		container[Columns.contactName] = contactName
		container[Columns.company] = company
		container[Columns.trade] = trade
	}
	
	enum Columns: String, CodingKey, ColumnExpression {
		case constructionSiteID
		
		case contactName
		case company
		case trade
	}
}
