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
	let parentID: ID<MapHolder>
	
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
}

extension Map: APIObject {}

extension Map: FileContainer {
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
}

extension Map: MapHolder {
	// TODO: it'd be great to use a recursive common table expression for this
	func recursiveChildren(in db: Database) throws -> [Map] {
		return try [self] + children.fetchAll(db).flatMap { try $0.recursiveChildren(in: db) }
	}
}

extension Map {
	var hasChildren: Bool {
		return Repository.shared.hasChildren(for: self)
	}
	
	func accessSite() -> ConstructionSite {
		return Repository.shared.site(constructionSiteID)!
	}
}
