// Created by Julian Dunskus

import Foundation
import Promise

struct ReadRequest: JSONJSONRequest {
	static let isIndependent = false
	
	var method: String { return "read" }
	
	let authenticationToken: String
	let user: ObjectMeta<User>
	let craftsmen: [ObjectMeta<Craftsman>]
	let buildings: [ObjectMeta<Building>]
	let maps: [ObjectMeta<Map>]
	let issues: [ObjectMeta<Issue>]
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.update(from: response)
	}
	
	func decode(from data: Data, using decoder: JSONDecoder) throws -> ExpectedResponse {
		let raw: Data
		if defaults.useFakeReadResponse {
			let path = Bundle.main.path(forResource: "fake_read_response.private", ofType: "json")!
			raw = try Data(contentsOf: URL(fileURLWithPath: path))
		} else {
			raw = data
		}
		return try decoder.decode(JSendSuccess<ExpectedResponse>.self, from: raw).data
	}
	
	struct ExpectedResponse: Response {
		let changedCraftsmen: [Craftsman]
		let removedCraftsmanIDs: [ID<Craftsman>]
		let changedBuildings: [Building]
		let removedBuildingIDs: [ID<Building>]
		let changedMaps: [Map]
		let removedMapIDs: [ID<Map>]
		let changedIssues: [Issue]
		let removedIssueIDs: [ID<Issue>]
		let changedUser: User?
	}
}

extension Client {
	func read() -> Future<Void> {
		return getUser()
			.map { user in
				ReadRequest(
					authenticationToken: user.authenticationToken,
					user: user.meta,
					craftsmen: self.storage.craftsmen.values.map { $0.meta },
					buildings: self.storage.buildings.values.map { $0.meta },
					maps:      self.storage.maps     .values.map { $0.meta },
					issues:    self.storage.issues   .values.map { $0.meta }
				)
			}
			.flatMap(Client.shared.send)
			.ignoringResult()
	}
	
	fileprivate func update(from response: ReadRequest.ExpectedResponse) {
		updateEntries(in: \.craftsmen, changing: response.changedCraftsmen, removing: response.removedCraftsmanIDs)
		updateEntries(in: \.buildings, changing: response.changedBuildings, removing: response.removedBuildingIDs)
		updateEntries(in: \.maps,      changing: response.changedMaps,      removing: response.removedMapIDs)
		updateEntries(in: \.issues,    changing: response.changedIssues,    removing: response.removedIssueIDs)
		
		if let newUser = response.changedUser {
			user = newUser
		}
		
		let removed = Set(response.removedIssueIDs) // for efficient lookup
		for map in storage.maps.values {
			map.issues.removeAll(where: { removed.contains($0) })
		}
		
		for issue in response.changedIssues {
			if let map = storage.maps[issue.map], !map.issues.contains(issue.id) {
				map.issues.append(issue.id)
			}
		}
		
		saveShared()
	}
	
	private func updateEntries<T: APIObject>(
		in path: WritableKeyPath<Storage, [ID<T>: T]>,
		changing changedEntries: [T],
		removing removedIDs: [ID<T>])
	{
		for changed in changedEntries {
			let previous = storage[keyPath: path][changed.id]
			storage[keyPath: path][changed.id] = changed
			if let container = changed as? AnyFileContainer {
				container.downloadFile(previous: previous as? AnyFileContainer)
			}
		}
		for removed in removedIDs {
			if let container = storage[keyPath: path][removed] as? AnyFileContainer {
				container.deleteFile()
			}
			storage[keyPath: path][removed] = nil
		}
	}
}
