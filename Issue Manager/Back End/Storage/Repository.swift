// Created by Julian Dunskus

import Foundation
import GRDB

final class Repository {
	static let shared = Repository()
	
	static func read<Result>(_ block: (Database) throws -> Result) -> Result {
		shared.read(block)
	}
	
	static func object<Object>(_ id: ID<Object>) -> Object? where Object: DBRecord {
		shared.object(id)
	}
	
	private let dataStore: DatabaseDataStore
	
	init() {
		self.dataStore = try! DatabaseDataStore()
	}
	
	func resetAllData() {
		try! dataStore.dbPool.write { db in
			try Issue.deleteAll(db)
			try Map.deleteAll(db)
			try Craftsman.deleteAll(db)
			try ConstructionSite.deleteAll(db)
		}
	}
	
	func read<Result>(_ block: (Database) throws -> Result) -> Result {
		try! dataStore.dbPool.read(block)
	}
	
	private func write<Result>(_ block: (Database) throws -> Result) -> Result {
		try! dataStore.dbPool.write(block)
	}
	
	func object<Object>(_ id: ID<Object>) -> Object? where Object: DBRecord {
		read(id.get)
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
	// MARK: Management
	
	func remove(_ issue: Issue, notifyingServer: Bool = true) {
		assert(!issue.isRegistered)
		
		let existed = write(issue.delete)
		assert(existed)
		Issue.onChange(from: issue, to: nil)
		
		if notifyingServer {
			Client.shared.issueRemoved(issue)
		}
	}
	
	func downloadMissingFiles() {
		func downloadFiles<Object>(for type: Object.Type, qos: DispatchQoS.QoSClass) where Object: FileContainer & DBRecord {
			DispatchQueue.global(qos: qos).async {
				self.read(Object.fetchAll).forEach { $0.downloadFile() }
			}
		}
		
		downloadFiles(for: ConstructionSite.self, qos: .userInitiated)
		downloadFiles(for: Map.self, qos: .default)
		downloadFiles(for: Issue.self, qos: .utility)
	}
	
	func update<Object>(in db: Database, changing changedEntries: [Object]) throws where Object: StoredObject & DBRecord {
		// this may seem overcomplicated, but it's actually a significant (>2x) performance improvement over the naive version and massively reduces database operations thanks to `updateChanges`
		
		let previous = Dictionary(uniqueKeysWithValues:
			try Object.fetchAll(db, keys: changedEntries.map { $0.id }).map { ($0.id, $0) }
		)
		for object in changedEntries {
			if let old = previous[object.id] {
				Object.onChange(from: old, to: object)
				try object.updateChanges(db, from: old)
			} else {
				Object.onChange(from: nil, to: object)
				try object.insert(db)
			}
		}
	}
	
	func update<Object>(in db: Database, removing removedIDs: [ID<Object>]) throws where Object: StoredObject & DBRecord {
		let removed = try Object.fetchAll(db, keys: removedIDs)
		removed.forEach { Object.onChange(from: $0, to: nil) }
		try Object.deleteAll(db, keys: removedIDs)
	}
	
	// TODO: this is just a shim until we revise the backlog system
	func updateIssues(in db: Database, removing removedIDs: [ID<Issue>]) throws {
		let toRemove = try Issue.fetchAll(db, keys: removedIDs)
		
		// don't remove issues that haven't been uploaded yet
		for issue in toRemove {
			if issue.wasUploaded {
				Issue.onChange(from: issue, to: nil)
				try issue.delete(db)
			} else {
				// server must have not gotten this somehow; try to send it again
				print("saving issue \(issue)")
				Client.shared.issueCreated(issue)
			}
		}
	}
	
	func update(from response: ReadRequest.ExpectedResponse) {
		write { db in
			// this order makes sure we don't violate foreign key constraints
			try update(in: db, changing: response.constructionSites())
			try update(in: db, changing: response.craftsmen())
			try update(in: db, changing: response.maps())
			try update(in: db, changing: response.issues())
			try updateIssues(in: db, removing: response.removedIssueIDs)
			try update(in: db, removing: response.removedMapIDs)
			try update(in: db, removing: response.removedCraftsmanIDs)
			try update(in: db, removing: response.removedConstructionSiteIDs)
		}
	}
}
