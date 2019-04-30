// Created by Julian Dunskus

import Foundation
import Promise
import GRDB

protocol DataStore {
	func loadStorage() throws -> Storage?
	func save(_ storage: Storage) -> Future<Void>
}

/// saving to disk is done on this queue to avoid blocking
private let savingQueue = DispatchQueue(label: "saving repository")

extension UserDefaults: DataStore {
	static let storageKey = "Repository.shared.storage"
	
	func loadStorage() throws -> Storage? {
		return try defaults.decode(forKey: UserDefaults.storageKey)
	}
	
	func save(_ storage: Storage) -> Future<Void> {
		return Future(asyncOn: savingQueue) {
			try self.encode(storage, forKey: UserDefaults.storageKey)
		}
	}
}

final class DatabaseDataStore {
	var dbPool: DatabasePool
	
	init(path: String) throws {
		dbPool = try .init(path: path)
	}
}

extension DatabaseDataStore: DataStore {
	func loadStorage() throws -> Storage? {
		let storage = Storage()
		try dbPool.read { db in
			storage.craftsmen = .init(uniqueKeysWithValues: try Craftsman.fetchAll(db).map { ($0.id, $0) })
		}
		return storage
	}
	
	func save(_ storage: Storage) -> Future<Void> {
		return .init {
			try dbPool.write { db in
				try Craftsman.deleteAll(db)
				try storage.craftsmen.values.forEach { try $0.insert(db) }
			}
		}
	}
}

extension Craftsman: PersistableRecord {}
extension Craftsman: FetchableRecord {}

extension ConstructionSite: PersistableRecord {}
extension ConstructionSite: FetchableRecord {}

extension Map: PersistableRecord {}
extension Map: FetchableRecord {}

extension Issue: PersistableRecord {}
extension Issue: FetchableRecord {}
