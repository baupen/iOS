// Created by Julian Dunskus

@testable import Issue_Manager
import Foundation

struct TestingContext: Sendable {
	let server: MockServer
	let repository: Repository
	let client: Client
	let syncManager: SyncManager
	
	init() throws {
		server = MockServer()
		repository = Repository(dataStore: try .temporary())
		client = Client { [server] in MockServer.Context(client: $0, loginInfo: $1, server: server) }
		syncManager = SyncManager(client: client, repository: repository)
	}
	
	@MainActor
	func setUpBasics() -> (ConstructionManager, ConstructionSite, Map) {
		let user = ConstructionManager(meta: .init())
		let site = ConstructionSite(
			meta: .init(),
			name: "Example Site",
			creationTime: .now,
			image: nil,
			managerIDs: [user.id]
		)
		let map = Map(
			meta: .init(),
			constructionSiteID: site.id,
			name: "Example Map",
			file: .init(urlPath: "example.pdf"),
			parentID: nil
		)
		
		client.mockLogIn(
			loginInfo: .init(token: "", origin: URL(string: "https://example.com")!),
			user: user, repository: repository
		)
		
		// only update after logging in, because that resets the repo
		repository.update(changing: [user])
		repository.update(changing: [site])
		repository.update(changing: [map])
		
		return (user, site, map)
	}
}

struct ExpectedError: Error {}
