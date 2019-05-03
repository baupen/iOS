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
		write { db in
			func update<Object>(changing changedEntries: [Object], removing removedIDs: [ID<Object>]) where Object: APIObject & DBRecord {
				for changed in changedEntries {
					var object = try! changed.id.get(in: db)
					Object.update(&object, from: changed)
					try! object!.save(db)
				}
				for removed in removedIDs {
					_ = try! Object.deleteOne(db, key: removed)
				}
			}
			
			update(
				changing: response.changedConstructionSites,
				removing: response.removedConstructionSiteIDs
			)
			update(
				changing: response.changedMaps,
				removing: response.removedMapIDs
			)
			update(
				changing: response.changedIssues,
				removing: response.removedIssueIDs
			)
			update(
				changing: response.changedCraftsmen,
				removing: response.removedCraftsmanIDs
			)
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
