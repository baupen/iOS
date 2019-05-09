// Created by Julian Dunskus

import Foundation
import GRDB

final class Repository {
	static let shared = Repository()
	
	static func read<Result>(_ block: (Database) throws -> Result) -> Result {
		return shared.read(block)
	}
	
	static func object<Object>(_ id: ID<Object>) -> Object? where Object: DBRecord {
		return shared.object(id)
	}
	
	private let dataStore: DatabaseDataStore
	
	init() {
		self.dataStore = try! DatabaseDataStore()
	}
	
	func resetAllData() {
		try! dataStore.dbPool.write { db in
			try ConstructionSite.deleteAll(db)
			try Map.deleteAll(db)
			try Issue.deleteAll(db)
			try Craftsman.deleteAll(db)
		}
	}
	
	func read<Result>(_ block: (Database) throws -> Result) -> Result {
		return try! dataStore.dbPool.read(block)
	}
	
	private func write<Result>(_ block: (Database) throws -> Result) -> Result {
		return try! dataStore.dbPool.write(block)
	}
	
	func object<Object>(_ id: ID<Object>) -> Object? where Object: DBRecord {
		return read(id.get)
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
		Issue.didChange(from: issue, to: nil)
		
		if notifyingServer {
			Client.shared.issueRemoved(issue)
		}
	}
	
	func downloadMissingFiles() {
		#warning("TODO")
	}
	
	func update<Object>(changing changedEntries: [Object], removing removedIDs: [ID<Object>]) throws where Object: StoredObject & DBRecord {
		try dataStore.dbPool.write { db in
			for new in changedEntries {
				try new.save(db)
				Object.didChange(from: try new.id.get(in: db), to: new)
			}
			
			try Object.deleteAll(db, keys: removedIDs)
			for removedID in removedIDs {
				Object.didChange(from: try removedID.get(in: db), to: nil)
			}
		}
	}
}
