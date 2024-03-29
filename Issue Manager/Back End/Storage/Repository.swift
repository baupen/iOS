// Created by Julian Dunskus

import Foundation
import GRDB
import UserDefault

final class Repository: Sendable {
	private let dataStore: DatabaseDataStore
	private let userTracker = UserTracker()
	
	init(dataStore: DatabaseDataStore) {
		self.dataStore = dataStore
	}
	
	@MainActor
	func signedIn(as manager: ConstructionManager) {
		userTracker.switchUser(to: manager, ifChanged: {
			resetAllData()
		})
	}
	
	func resetAllData() {
		try! dataStore.accessor.write { db in
			try Issue.deleteAll(db)
			try Map.deleteAll(db)
			try Craftsman.deleteAll(db)
			try ConstructionSite.deleteAll(db)
			try ConstructionManager.deleteAll(db)
		}
	}
	
	func read<Result>(_ block: (Database) throws -> Result) -> Result {
		try! dataStore.accessor.read(block)
	}
	
	private func write<Result>(_ block: (Database) throws -> Result) -> Result {
		try! dataStore.accessor.write(block)
	}
	
	func object<Object>(_ id: Object.ID) -> Object? where Object: StoredObject {
		read(id.get)
	}
	
	/// saves modifications to an issue
	func save(_ issue: Issue) {
		write { try issue.save($0) }
	}
	
	/// saves modifications to some columns of an issue
	func save(_ columns: [Issue.Columns], of issue: Issue) {
		write { try issue.update($0, columns: columns) }
	}
	
	func remove(_ issue: Issue) {
		let wasDeleted = write(issue.delete)
		assert(wasDeleted)
	}
	
	@discardableResult
	func ensureNotPresent(_ site: ConstructionSite) -> Bool {
		write(site.delete)
	}
	
	// MARK: -
	// MARK: Management
	
	func update<Object>(changing changedEntries: [Object]) where Object: StoredObject {
		write { db in
			// this may seem overcomplicated, but it's actually a significant (>2x) performance improvement over the naive version and massively reduces database operations thanks to `updateChanges`
			
			let previous = Dictionary(
				uniqueKeysWithValues: try Object
					.fetchAll(db, keys: changedEntries.map { $0.id })
					.map { ($0.id, $0) }
			)
			for object in changedEntries {
				if let old = previous[object.id] {
					try object.updateChanges(db, from: old)
				} else {
					try object.insert(db)
				}
			}
		}
	}
	
	@MainActor
	private final class UserTracker: Sendable {
		@UserDefault("repository.userID") private var userID: ConstructionManager.ID?
		
		nonisolated init() {}
		
		/// Calls `ifChanged` whenever the user changes, before storing the new user.
		func switchUser(to manager: ConstructionManager, ifChanged: () -> Void) {
			guard manager.id != userID else { return } // nothing changed
			ifChanged()
			userID = manager.id
		}
	}
	
}

extension ObjectID: DefaultsValueConvertible {}
