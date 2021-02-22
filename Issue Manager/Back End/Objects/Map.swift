// Created by Julian Dunskus

import Foundation
import GRDB

struct Map {
	let meta: Meta
	let constructionSiteID: ConstructionSite.ID
	
	let name: String
	let file: File<Map>?
	let parentID: Map.ID?
	
	var parentHolderID: UUID {
		parentID?.rawValue ?? constructionSiteID.rawValue
	}
}

extension Map: DBRecord {
	static let site = belongsTo(ConstructionSite.self)
	var site: QueryInterfaceRequest<ConstructionSite> {
		request(for: Self.site)
	}
	
	static let issues = hasMany(Issue.self)
	var issues: QueryInterfaceRequest<Issue> {
		request(for: Self.issues).withoutDeleted.consideringClientMode
	}
	
	var sortedIssues: QueryInterfaceRequest<Issue> {
		issues.withoutDeleted.order(Issue.Columns.number.asc, Issue.Meta.Columns.lastChangeTime.desc)
	}
	
	static let children = hasMany(Map.self)
	var children: QueryInterfaceRequest<Map> {
		request(for: Self.children).withoutDeleted
	}
	
	func hasChildren(in db: Database) throws -> Bool {
		try children.fetchCount(db) > 0 // TODO: SQL exists() might be nice here
	}
	
	init(row: Row) {
		meta = .init(row: row)
		constructionSiteID = row[Columns.constructionSiteID]
		
		file = row[Columns.file]
		name = row[Columns.name]
		parentID = row[Columns.parentID]
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		container[Columns.constructionSiteID] = constructionSiteID
		
		container[Columns.file] = file
		container[Columns.name] = name
		container[Columns.parentID] = parentID
	}
	
	enum Columns: String, ColumnExpression {
		case constructionSiteID
		
		case file
		case name
		case parentID
	}
}

extension Map: StoredObject {
	typealias Model = APIMap
	static let apiType = "maps"
}

extension Map: FileContainer {
	static let pathPrefix = "map"
}
