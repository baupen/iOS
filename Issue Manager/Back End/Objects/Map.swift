// Created by Julian Dunskus

import Foundation
import GRDB

struct Map {
	let meta: ObjectMeta<Map>
	let sectors: [Sector]
	let sectorFrame: Rectangle?
	let file: File<Map>?
	let name: String
	let constructionSiteID: ID<ConstructionSite>
	let parentID: ID<Map>?
	
	var parentHolderID: UUID {
		parentID?.rawValue ?? constructionSiteID.rawValue
	}
	
	final class Sector: Codable {
		let name: String
		let color: Color
		let points: [Point]
	}
}

extension Map: DBRecord {
	static let site = belongsTo(ConstructionSite.self)
	var site: QueryInterfaceRequest<ConstructionSite> {
		request(for: Map.site)
	}
	
	static let issues = hasMany(Issue.self)
	var issues: QueryInterfaceRequest<Issue> {
		request(for: Map.issues).consideringClientMode
	}
	
	var sortedIssues: QueryInterfaceRequest<Issue> {
		issues.order(Issue.Columns.number.asc, Issue.Meta.Columns.lastChangeTime.desc)
	}
	
	static let children = hasMany(Map.self)
	var children: QueryInterfaceRequest<Map> {
		request(for: Map.children)
	}
	
	func hasChildren(in db: Database) throws -> Bool {
		try children.fetchCount(db) > 0 // TODO: SQL exists() might be nice here
	}
	
	init(row: Row) {
		meta = .init(row: row)
		sectors = try! row.decodeValue(forKey: Columns.sectors)
		sectorFrame = try! row.decodeValueIfPresent(forKey: Columns.sectorFrame)
		file = try! row.decodeValueIfPresent(forKey: Columns.file)
		name = row[Columns.name]
		constructionSiteID = row[Columns.constructionSiteID]
		parentID = row[Columns.parentID]
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		try! container.encode(sectors, forKey: Columns.sectors)
		sectorFrame.map { try! container.encode($0, forKey: Columns.sectorFrame) }
		file.map { try! container.encode($0, forKey: Columns.file) }
		container[Columns.name] = name
		container[Columns.constructionSiteID] = constructionSiteID
		container[Columns.parentID] = parentID
	}
	
	enum Columns: String, ColumnExpression {
		case sectors
		case sectorFrame
		case file
		case name
		case constructionSiteID
		case parentID
	}
}

extension Map: StoredObject {}

extension Map: FileContainer {
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
}
