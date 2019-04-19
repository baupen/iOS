// Created by Julian Dunskus

import Foundation
import Promise

struct ReadRequest: JSONJSONRequest {
	static let isIndependent = false
	
	var method: String { return "read" }
	
	let authenticationToken: String
	let user: ObjectMeta<User>
	let craftsmen: [ObjectMeta<Craftsman>]
	let constructionSites: [ObjectMeta<ConstructionSite>]
	let maps: [ObjectMeta<Map>]
	let issues: [ObjectMeta<Issue>]
	
	func applyToClient(_ response: ExpectedResponse) {
		if let newUser = response.changedUser {
			assert(Client.shared.localUser?.user.id == newUser.id)
			Client.shared.localUser?.user = newUser
		}
		
		Repository.shared.update(from: response)
	}
	
	func decode(from data: Data, using decoder: JSONDecoder) throws -> ExpectedResponse {
		let raw: Data
		if defaults.useFakeReadResponse {
			let path = Bundle.main.path(forResource: "fake_read_response.private", ofType: "json")!
			raw = try Data(contentsOf: URL(fileURLWithPath: path))
		} else {
			raw = data
		}
		return try decoder.decode(JSend.Success<ExpectedResponse>.self, from: raw).data
	}
	
	struct ExpectedResponse: Response {
		let changedCraftsmen: [Craftsman]
		let removedCraftsmanIDs: [ID<Craftsman>]
		let changedConstructionSites: [ConstructionSite]
		let removedConstructionSiteIDs: [ID<ConstructionSite>]
		let changedMaps: [Map]
		let removedMapIDs: [ID<Map>]
		let changedIssues: [Issue]
		let removedIssueIDs: [ID<Issue>]
		let changedUser: User?
	}
}

private extension Repository {
	func makeReadRequest(_ user: User) -> ReadRequest {
		return ReadRequest(
			authenticationToken: user.authenticationToken,
			user: user.meta,
			craftsmen: craftsmanMetas(),
			constructionSites: siteMetas(),
			maps: mapMetas(),
			issues: issueMetas()
		)
	}
	
	func update(from response: ReadRequest.ExpectedResponse) {
		edit { storage in
			storage.craftsmen.update(
				changing: response.changedCraftsmen,
				removing: response.removedCraftsmanIDs
			)
			storage.sites.update(
				changing: response.changedConstructionSites,
				removing: response.removedConstructionSiteIDs
			)
			storage.maps.update(
				changing: response.changedMaps,
				removing: response.removedMapIDs
			)
			storage.issues.update(
				changing: response.changedIssues,
				removing: response.removedIssueIDs
			)
			
			for issue in response.changedIssues {
				self[issue.map]?.add(issue)
			}
			
			for issue in response.removedIssueIDs.compactMap(Repository.shared.issue) {
				self[issue.map]?.remove(issue.id)
			}
		}
	}
}

private extension Dictionary where Value: APIObject, Key == ID<Value> {
	mutating func update(changing changedEntries: [Value], removing removedIDs: [ID<Value>]) {
		for changed in changedEntries {
			Value.update(&self[changed.id], from: changed)
		}
		for removed in removedIDs {
			Value.update(&self[removed], from: nil)
		}
	}
}

extension Client {
	func read() -> Future<Void> {
		return getUser()
			.map(Repository.shared.makeReadRequest)
			.flatMap(send)
			.ignoringResult()
	}
}
