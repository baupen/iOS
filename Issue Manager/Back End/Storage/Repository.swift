// Created by Julian Dunskus

import Foundation
import GRDB

final class Repository {
	static let shared = Repository()
	
	private var dbPool: DatabasePool { return dataStore.dbPool }
	private let dataStore: DatabaseDataStore
	
	init() {
		self.dataStore = try! DatabaseDataStore()
	}
	
	func clearStorage() {
		dataStore.clear()
	}
	
	func read<Result>(_ block: (Database) throws -> Result) -> Result {
		return try! dbPool.read(block)
	}
	
	func write<Result>(_ block: (Database) throws -> Result) -> Result {
		return try! dbPool.write(block)
	}
	
	/// saves modifications to the given issue
	func save(_ issue: Issue) {
		try! dbPool.write(issue.save)
	}
	
	/// saves modifications to the given map
	func save(_ map: Map) {
		try! dbPool.write(map.save)
	}
	
	// MARK: -
	// MARK: Access by ID
	
	func site(_ id: ID<ConstructionSite>) -> ConstructionSite? {
		return try! dbPool.read(id.get)
	}
	
	func map(_ id: ID<Map>) -> Map? {
		return try! dbPool.read(id.get)
	}
	
	func issue(_ id: ID<Issue>) -> Issue? {
		return try! dbPool.read(id.get)
	}
	
	func craftsman(_ id: ID<Craftsman>) -> Craftsman? {
		return try! dbPool.read(id.get)
	}
	
	// MARK: -
	// MARK: Metas
	
	func siteMetas() -> [ObjectMeta<ConstructionSite>] {
		return try! dbPool.read(ObjectMeta.fetchAll)
	}
	
	func mapMetas() -> [ObjectMeta<Map>] {
		return try! dbPool.read(ObjectMeta.fetchAll)
	}
	
	func issueMetas() -> [ObjectMeta<Issue>] {
		return try! dbPool.read(ObjectMeta.fetchAll)
	}
	
	func craftsmanMetas() -> [ObjectMeta<Craftsman>] {
		return try! dbPool.read(ObjectMeta.fetchAll)
	}
	
	// MARK: -
	// MARK: Other Accessors
	
	func site(for issue: Issue) -> ConstructionSite? {
		return try! dbPool.read { db in
			try issue.mapID.get(in: db)!.constructionSiteID.get(in: db)!
		}
	}
	
	func sites() -> [ConstructionSite] {
		return try! dbPool.read(ConstructionSite.fetchAll)
	}
	
	func issues(in holder: MapHolder, recursively: Bool) -> AnyCollection<Issue> {
		return recursively
			? recursiveIssues(in: holder)
			: AnyCollection(issues(in: holder as! Map))
	}
	
	func recursiveIssues(in holder: MapHolder) -> AnyCollection<Issue> {
		return try! dbPool.read(holder.recursiveIssues)
	}
	
	func issues(in map: Map) -> [Issue] {
		return try! dbPool.read(map.issues.fetchAll)
	}
	
	func children(of holder: MapHolder) -> [Map] {
		return try! dbPool.read(holder.children.fetchAll)
	}
	
	func hasChildren(for map: Map) -> Bool {
		return try! dbPool.read(map.children.fetchCount) > 0
	}
	
	func craftsmen(in site: ConstructionSite) -> [Craftsman] {
		return try! dbPool.read(site.craftsmen.fetchAll)
	}
	
	func craftsman(for issue: Issue) -> Craftsman? {
		return try! (issue.craftsmanID?.get).flatMap(dbPool.read)
	}
	
	// MARK: -
	// MARK: Management
	
	func add(_ issue: Issue) {
		assert(self.issue(issue.id) == nil)
		
		try! dbPool.write(issue.save)
		Client.shared.issueCreated(issue)
	}
	
	func update(_ new: Issue) {
		// TODO: remove?
		save(new)
	}
	
	func remove(_ issue: Issue, notifyingServer: Bool = true) {
		assert(!issue.isRegistered)
		
		issue.deleteFile()
		let existed = try! dbPool.write(issue.delete)
		assert(existed)
		
		if notifyingServer {
			Client.shared.issueRemoved(issue)
		}
	}
	
	func downloadMissingFiles() {
		#warning("TODO typed files (like IDs)")
	}
}

extension QueryInterfaceRequest where T == Issue {
	var consideringClientMode: QueryInterfaceRequest<Issue> {
		return defaults.isInClientMode ? filter(Issue.Columns.wasAddedWithClient == true) : self
	}
}
