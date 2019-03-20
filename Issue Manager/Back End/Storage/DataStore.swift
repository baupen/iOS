// Created by Julian Dunskus

import Foundation
import Promise

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
