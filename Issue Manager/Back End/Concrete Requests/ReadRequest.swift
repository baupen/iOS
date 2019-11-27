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
		let changedCraftsmen: [APICraftsman]
		let removedCraftsmanIDs: [ID<Craftsman>]
		let changedConstructionSites: [APIConstructionSite]
		let removedConstructionSiteIDs: [ID<ConstructionSite>]
		let changedMaps: [APIMap]
		let removedMapIDs: [ID<Map>]
		let changedIssues: [APIIssue]
		let removedIssueIDs: [ID<Issue>]
		let changedUser: User?
		
		func constructionSites() -> [ConstructionSite] {
			return changedConstructionSites.map { $0.makeObject() }
		}
		
		func maps() -> [Map] {
			return changedMaps.map { $0.makeObject() }
		}
		
		func issues() -> [Issue] {
			return changedIssues.map { $0.makeObject() }
		}
		
		func craftsmen() -> [Craftsman] {
			return changedCraftsmen.map { $0.makeObject() }
		}
	}
}

private extension Repository {
	func makeReadRequest(_ user: User) -> ReadRequest {
		return ReadRequest(
			authenticationToken: user.authenticationToken,
			user: user.meta,
			craftsmen: read(ObjectMeta.fetchAll),
			constructionSites: read(ObjectMeta.fetchAll),
			maps: read(ObjectMeta.fetchAll),
			issues: read(ObjectMeta.fetchAll)
		)
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
