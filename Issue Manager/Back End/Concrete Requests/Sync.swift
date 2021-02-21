// Created by Julian Dunskus

import Foundation
import Promise
import GRDB

struct GetObjectsRequest<Model: APIModel>: GetRequest, JSONDecodingRequest {
	typealias Response = HydraCollection<APIObject<Model>>
	
	var path: String { Model.Object.apiPath }
	
	var constructionSite: ConstructionSite.ID?
	var minLastChangeTime: Date
	
	func collectURLQueryItems() -> [(String, Any)] {
		if let constructionSite = constructionSite {
			("constructionSite", constructionSite)
		}
		
		("lastChangedAt[after]", Client.dateFormatter.string(from: minLastChangeTime))
	}
}

struct GetPagedObjectsRequest<Model: APIModel>: GetRequest, JSONDecodingRequest {
	typealias Response = PagedHydraCollection<APIObject<Model>>
	
	var path: String { Model.Object.apiPath }
	
	var constructionSite: ConstructionSite.ID?
	var minLastChangeTime: Date
	var page = 1
	var itemsPerPage = 10 // TODO: increase!
	
	func collectURLQueryItems() -> [(String, Any)] {
		if let constructionSite = constructionSite {
			("constructionSite", constructionSite)
		}
		
		("lastChangedAt[after]", Client.dateFormatter.string(from: minLastChangeTime))
		("order[lastChangedAt]", "asc")
		
		("page", page)
		("itemsPerPage", itemsPerPage)
	}
}

private struct IssuePatchRequest: JSONJSONRequest {
	typealias Response = APIObject<APIIssue>
	static let httpMethod = "PATCH"
	
	var path: String
	let body: IssuePatch
}

/// - Note: The double optionals represent setting a value to nil (`.some(nil)`) vs not affecting it (`.none`)
struct IssuePatch: Codable {
	var isMarked: Bool?
	var wasAddedWithClient: Bool?
	var description: String??
	
	var craftsman: Craftsman.ID??
	var map: Map.ID??
	var constructionSite: ConstructionSite.ID??
	
	var positionX: Double??
	var positionY: Double??
	var positionZoomScale: Double??
	
	var createdAt: Date?
	var createdBy: ConstructionManager.ID?
	var resolvedAt: Date??
	var resolvedBy: Craftsman.ID??
	var closedAt: Date??
	var closedBy: ConstructionManager.ID??
}

extension Client {
	private static let issuePatchLimiter = ConcurrencyLimiter(label: "issue patch", maxConcurrency: 16)
	
	func pushLocalChanges() -> Future<Void> {
		pushChangesThen {}
	}
	
	func synchronouslyPushLocalChanges() throws {
		assert(isOnLinearQueue)
		let changesQuery = Issue.filter(Issue.Columns.patchIfChanged != nil)
		try Repository.shared.read(changesQuery.fetchAll)
			.map { IssuePatchRequest(path: $0.apiPath, body: $0.patchIfChanged!) }
			.traverse { request in
				// TODO: I'm 99% sure this handles things concurrently, but I should check
				Self.issuePatchLimiter
					.dispatch { self.send(request) }
					.ignoringResult()
			}
			.await()
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges() -> Future<Void> {
		pushChangesThen {
			try self.doPullRemoteChanges().await()
			Repository.shared.downloadMissingFiles()
		}
	}
	
	private func doPullRemoteChanges() -> Future<Void> {
		// TODO: what about construction manager changes? e.g. name changed
		let request = GetObjectsRequest<APIConstructionSite>(
			minLastChangeTime: ConstructionSite.all().maxLastChangeTime()
		)
		return send(request)
			.map { $0.members.map { $0.makeObject() } }
			.flatMap { sites in
				Repository.shared.update(changing: sites)
				return sites.traverse(self.doPullRemoteChanges(for:))
			}
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges(for siteID: ConstructionSite.ID) -> Future<Void> {
		pullRemoteChanges(for: Repository.shared.read(siteID.get)!)
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges(for site: ConstructionSite) -> Future<Void> {
		pushChangesThen {
			try self.doPullRemoteChanges(for: site).await()
			Repository.shared.downloadMissingFiles()
		}
	}
	
	private func doPullRemoteChanges(for site: ConstructionSite) -> Future<Void> {
		[doPullChangedMaps(for: site), doPullChangedCraftsmen(for: site)]
			.sequence() // insert issues only after maps & craftsmen to keep intact foreign key constraints
			.flatMap { self.doPullChangedIssues(for: site) }
	}
	
	private func doPullChangedMaps(for site: ConstructionSite) -> Future<Void> {
		send(GetObjectsRequest<APIMap>(
			constructionSite: site.id,
			minLastChangeTime: site.maps.maxLastChangeTime()
		))
		.map { $0.members.map { $0.makeObject(context: site.id) } }
		.map(Repository.shared.update(changing:))
	}
	
	private func doPullChangedCraftsmen(for site: ConstructionSite) -> Future<Void> {
		send(GetObjectsRequest<APICraftsman>(
			constructionSite: site.id,
			minLastChangeTime: site.craftsmen.maxLastChangeTime()
		))
		.map { $0.members.map { $0.makeObject(context: site.id) } }
		.map(Repository.shared.update(changing:))
	}
	
	private func doPullChangedIssues(for site: ConstructionSite) -> Future<Void> {
		send(GetPagedObjectsRequest<APIIssue>(
			constructionSite: site.id,
			minLastChangeTime: site.issues.maxLastChangeTime()
		))
		.flatMap { collection in
			let issues = collection.members.map { $0.makeObject(context: site.id) }
			Repository.shared.update(changing: issues)
			
			return collection.view.nextPage == nil
				? .fulfilled
				: self.doPullChangedIssues(for: site)
		}
	}
}

private extension QueryInterfaceRequest where RowDecoder: StoredObject {
	func maxLastChangeTime() -> Date {
		Repository.shared.read(
			self
				.select(max(Issue.Meta.Columns.lastChangeTime), as: Date.self)
				.expectingSingleResult()
				.fetchOne
		) ?? .distantPast
	}
}
