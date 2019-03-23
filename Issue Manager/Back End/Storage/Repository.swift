// Created by Julian Dunskus

import Foundation

final class Repository {
	static let shared = Repository(dataStore: UserDefaults.standard)
	
	private var storage = Storage()
	private let dataStore: DataStore
	
	init(dataStore: DataStore) {
		self.dataStore = dataStore
		
		do {
			storage = try dataStore.loadStorage() ?? storage
		} catch {
			error.printDetails(context: "Repository could not be loaded!")
		}
	}
	
	private func saveAll() {
		dataStore.save(storage).catch { error in
			error.printDetails(context: "Repository could not be saved!")
		}
	}
	
	/// saves modifications to the given issue
	func save(_ issue: Issue) {
		// for now
		saveAll()
	}
	
	/// saves modifications to the given map
	func save(_ map: Map) {
		// for now
		saveAll()
	}
	
	func clearStorage() {
		storage = Storage()
	}
	
	func sites() -> [ConstructionSite] {
		return Array(storage.sites.values)
	}
	
	func siteMetas() -> [ObjectMeta<ConstructionSite>] {
		return storage.sites.values.map { $0.meta }
	}
	
	func site(_ id: ID<ConstructionSite>) -> ConstructionSite? {
		return storage.sites[id]
	}
	
	func mapMetas() -> [ObjectMeta<Map>] {
		return storage.maps.values.map { $0.meta }
	}
	
	func map(_ id: ID<Map>) -> Map? {
		return storage.maps[id]
	}
	
	func issueMetas() -> [ObjectMeta<Issue>] {
		return storage.issues.values.map { $0.meta }
	}
	
	func issue(_ id: ID<Issue>) -> Issue? {
		return storage.issues[id]
	}
	
	func craftsmanMetas() -> [ObjectMeta<Craftsman>] {
		return storage.craftsmen.values.map { $0.meta }
	}
	
	func craftsman(_ id: ID<Craftsman>) -> Craftsman? {
		return storage.craftsmen[id]
	}
	
	func add(_ issue: Issue) {
		assert(self.issue(issue.id) == nil)
		
		let map = self.map(issue.map)!
		storage.issues[issue.id] = issue
		map.add(issue)
		Client.shared.issueCreated(issue)
		
		saveAll() // no way to specifically save adding a new issue yet
	}
	
	func update(_ new: Issue) {
		Issue.update(&storage.issues[new.id], from: new)
	}
	
	func remove(_ issue: Issue, notifyingServer: Bool = true) {
		assert(!issue.isRegistered)
		
		let map = self.map(issue.map)!
		issue.deleteFile()
		storage.issues[issue.id] = nil
		map.remove(issue.id)
		
		if notifyingServer {
			Client.shared.issueRemoved(issue)
		}
		
		saveAll() // can't save lack of issue yet
	}
	
	func edit(_ edit: (Storage) throws -> Void) rethrows {
		try edit(storage)
		saveAll()
	}
	
	func downloadMissingFiles() {
		storage.downloadMissingFiles()
	}
}
