// Created by Julian Dunskus

import Foundation
import GRDB

final class Repository {
	static let shared = Repository()
	
	private let dataStore: DatabaseDataStore
	
	init() {
		self.dataStore = try! DatabaseDataStore()
	}
	
	func clearStorage() {
		dataStore.clear()
	}
	
	func read<Result>(_ block: (Database) throws -> Result) -> Result {
		return try! dataStore.dbPool.read(block)
	}
	
	func write<Result>(_ block: (Database) throws -> Result) -> Result {
		return try! dataStore.dbPool.write(block)
	}
	
	/// saves modifications to the given issue
	func save(_ issue: Issue) {
		write(issue.save)
	}
	
	/// saves modifications to the given map
	func save(_ map: Map) {
		write(map.save)
	}
	
	// MARK: -
	// MARK: Access by ID
	
	func site(_ id: ID<ConstructionSite>) -> ConstructionSite? {
		return read(id.get)
	}
	
	func map(_ id: ID<Map>) -> Map? {
		return read(id.get)
	}
	
	func issue(_ id: ID<Issue>) -> Issue? {
		return read(id.get)
	}
	
	func craftsman(_ id: ID<Craftsman>) -> Craftsman? {
		return read(id.get)
	}
	
	// MARK: -
	// MARK: Metas
	
	func siteMetas() -> [ObjectMeta<ConstructionSite>] {
		return read(ObjectMeta.fetchAll)
	}
	
	func mapMetas() -> [ObjectMeta<Map>] {
		return read(ObjectMeta.fetchAll)
	}
	
	func issueMetas() -> [ObjectMeta<Issue>] {
		return read(ObjectMeta.fetchAll)
	}
	
	func craftsmanMetas() -> [ObjectMeta<Craftsman>] {
		return read(ObjectMeta.fetchAll)
	}
	
	// MARK: -
	// MARK: Other Accessors
	
	func site(for issue: Issue) -> ConstructionSite? {
		return read { db in
			try issue.mapID.get(in: db)!.constructionSiteID.get(in: db)!
		}
	}
	
	func sites() -> [ConstructionSite] {
		return read(ConstructionSite.fetchAll)
	}
	
	func issues(in holder: MapHolder, recursively: Bool) -> QueryInterfaceRequest<Issue> {
		return recursively
			? holder.recursiveIssues
			: (holder as! Map).issues
	}
	
	func issues(in map: Map) -> [Issue] {
		return read(map.issues
			.order(Issue.Columns.number.asc, Column("lastChangeTime").desc)
			.fetchAll
		)
	}
	
	func children(of holder: MapHolder) -> [Map] {
		return read(holder.children.fetchAll)
	}
	
	func hasChildren(for map: Map) -> Bool {
		return read(map.children.fetchCount) > 0
	}
	
	func craftsmen(in site: ConstructionSite) -> [Craftsman] {
		return read(site.craftsmen.fetchAll)
	}
	
	func craftsman(for issue: Issue) -> Craftsman? {
		return (issue.craftsmanID?.get).flatMap(read)
	}
	
	// MARK: -
	// MARK: Management
	
	func remove(_ issue: Issue, notifyingServer: Bool = true) {
		assert(!issue.isRegistered)
		
		issue.deleteFile()
		let existed = write(issue.delete)
		assert(existed)
		
		if notifyingServer {
			Client.shared.issueRemoved(issue)
		}
	}
	
	func downloadMissingFiles() {
		#warning("TODO typed files (like IDs)")
	}
}
