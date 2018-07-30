// Created by Julian Dunskus

import Foundation

struct ReadRequest: JSONJSONRequest {
	static let isIndependent = false
	
	var method: String { return "read" }
	
	let authenticationToken: String
	let user: ObjectMeta
	let craftsmen: [ObjectMeta]
	let buildings: [ObjectMeta]
	let maps: [ObjectMeta]
	let issues: [ObjectMeta]
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.update(from: response)
	}
	
	struct ExpectedResponse: Response {
		let changedCraftsmen: [Craftsman]
		let removedCraftsmanIDs: [UUID]
		let changedBuildings: [Building]
		let removedBuildingIDs: [UUID]
		let changedMaps: [Map]
		let removedMapIDs: [UUID]
		let changedIssues: [Issue]
		let removedIssueIDs: [UUID]
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
			// TODO Swift 4.2: map.issues.removeAll(where: removed.contains)
			map.issues = map.issues.filter { !removed.contains($0) }
		}
		
		for issue in response.changedIssues {
			if let map = storage.maps[issue.map], !map.issues.contains(issue.id) {
				map.issues.append(issue.id)
			}
		}
		
		saveShared()
	}
	
	private func updateEntries<T: APIObject>(in path: WritableKeyPath<Storage, [UUID: T]>,
											 changing changedEntries: [T],
											 removing removedIDs: [UUID]) {
		for changed in changedEntries {
			let previous = storage[keyPath: path][changed.id]
			storage[keyPath: path][changed.id] = changed
			if let container = changed as? FileContainer {
				container.downloadFile(previous: previous as? FileContainer)
			}
		}
		for removed in removedIDs {
			if let container = storage[keyPath: path][removed] as? FileContainer {
				container.deleteFile()
			}
			storage[keyPath: path][removed] = nil
		}
	}
}
