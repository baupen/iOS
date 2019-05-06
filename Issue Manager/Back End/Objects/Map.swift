// Created by Julian Dunskus

import Foundation
import GRDB

struct Map {
	let meta: ObjectMeta<Map>
	let sectors: [Sector]
	let sectorFrame: Rectangle?
	let file: File?
	let name: String
	let constructionSiteID: ID<ConstructionSite>
	let parentID: ID<Map>?
	
	var parentHolderID: UUID {
		return parentID?.rawValue ?? constructionSiteID.rawValue
	}
	
	var hasChildren: Bool {
		return Repository.shared.hasChildren(for: self)
	}
	
	func accessSite() -> ConstructionSite {
		return Repository.shared.site(constructionSiteID)!
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
		return request(for: Map.site)
	}
	
	static let issues = hasMany(Issue.self)
	var issues: QueryInterfaceRequest<Issue> {
		return request(for: Map.issues).consideringClientMode
	}
	
	static let children = hasMany(Map.self)
	var children: QueryInterfaceRequest<Map> {
		return request(for: Map.children)
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
	
	init(row: Row) {
		meta = .init(row: row)
		sectors = try! row.decodeValue(forKey: Columns.sectors)
		sectorFrame = try! row.decodeValueIfPresent(forKey: Columns.sectorFrame)
		file = try! row.decodeValueIfPresent(forKey: Columns.file)
		name = row[Columns.name]
		constructionSiteID = row[Columns.constructionSiteID]
		parentID = row[Columns.parentID]
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
