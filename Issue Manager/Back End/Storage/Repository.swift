// Created by Julian Dunskus

import Foundation
import GRDB

final class Repository {
	static let shared = Repository()
	
	static func read<Result>(_ block: (Database) throws -> Result) -> Result {
		shared.read(block)
	}
	
	static func object<Object>(_ id: Object.ID) -> Object? where Object: StoredObject {
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
			try ConstructionManager.deleteAll(db)
		}
	}
	
	func read<Result>(_ block: (Database) throws -> Result) -> Result {
		try! dataStore.dbPool.read(block)
	}
	
	private func write<Result>(_ block: (Database) throws -> Result) -> Result {
		try! dataStore.dbPool.write(block)
	}
	
	func object<Object>(_ id: Object.ID) -> Object? where Object: StoredObject {
		read(id.get)
	}
	
	/// saves modifications to an issue
	func save(_ issue: Issue) {
		write(issue.save)
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
	
	/// saves modifications to a map
	func save(_ map: Map) {
		write(map.save)
	}
	
	// MARK: -
	// MARK: Management
	
	private static let fileDownloadQueue = DispatchQueue(label: "missing file downloads")
	func downloadMissingFiles() {
		func downloadFiles<Object>(for type: Object.Type) where Object: FileContainer {
			// TODO: There's definitely a faster way to do this than to just fetch everything.
			// On the other hand, the performance impact would be negligible compared to the time it takes to execute those requests…
			self.read(Object.fetchAll).forEach { $0.downloadFile() }
		}
		
		Self.fileDownloadQueue.async {
			downloadFiles(for: ConstructionSite.self)
			downloadFiles(for: Map.self)
			downloadFiles(for: Issue.self)
		}
	}
	
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
					Object.onChange(from: old, to: object)
					try object.updateChanges(db, from: old)
				} else {
					Object.onChange(from: nil, to: object)
					try object.insert(db)
				}
			}
		}
	}
}
