// Created by Julian Dunskus

import Foundation
import Promise
import GRDB

private struct IssuePatchRequest: JSONJSONRequest {
	typealias Response = APIObject<APIIssue>
	static let httpMethod = "PATCH"
	static let contentType: String? = "application/merge-patch+json"
	
	var path: String
	let body: APIIssuePatch
}

private struct IssueCreationRequest: JSONJSONRequest {
	typealias Response = APIObject<APIIssue>
	static let contentType: String? = "application/json"
	
	let path = Issue.apiPath
	let body: APIIssuePatch
}

private struct ImageUploadRequest: MultipartEncodingRequest, StatusCodeRequest {
	var path: String
	
	var fileURL: URL
	
	var parts: [MultipartPart] {
		MultipartPart(name: "image", content: .jpeg(at: fileURL))
	}
	
	init(issue: Issue, fileURL: URL) {
		self.path = "\(issue.apiPath)/image"
		self.fileURL = fileURL
	}
}

private struct DeletionRequest: GetRequest, StatusCodeRequest {
	static var httpMethod: String { "DELETE" }
	
	var path: String
	
	init(for issue: Issue) {
		path = issue.apiPath
	}
	
	init(forImageOf issue: Issue) {
		path = "\(issue.apiPath)/image"
	}
}

extension Client {
	private static let issuePatchLimiter = ConcurrencyLimiter(label: "issue patch", maxConcurrency: 16)
	
	func pushLocalChanges() -> Future<Void> {
		pushChangesThen {}
	}
	
	func synchronouslyPushLocalChanges() throws {
		assertOnLinearQueue()
		
		try syncChanges(for: Issue.filter(Issue.Columns.patchIfChanged != nil)) { issue in
			let result = issue.wasUploaded
				? self.send(IssuePatchRequest(path: issue.apiPath, body: issue.patchIfChanged!.makeModel()))
				: self.send(IssueCreationRequest(body: issue.patchIfChanged!.makeModel()))
			return result.map {
				Repository.shared.remove(issue) // remove non-canonical copy
				Repository.shared.save($0.makeObject(context: issue.constructionSiteID) <- {
					$0.image = issue.image // keep local changes to image to sync next
				})
			}
		}
		
		try syncChanges(for: Issue.filter(Issue.Columns.didChangeImage)) { issue in
			let result = issue.image
				.map { self.send(ImageUploadRequest(issue: issue, fileURL: Issue.localURL(for: $0))) }
				?? self.send(DeletionRequest(forImageOf: issue))
			return result.map {
				let newState = issue <- { $0.didChangeImage = false }
				   Repository.shared.save([.didChangeImage], of: newState)
			}
		}
		
		try syncChanges(for: Issue.filter(Issue.Columns.didDelete)) { issue in
			self.send(DeletionRequest(for: issue)).map {
				let newState = issue <- { $0.didDelete = false }
				   Repository.shared.save([.didDelete], of: newState)
			}
		}
	}
	
	private func syncChanges(for query: QueryInterfaceRequest<Issue>, performing upload: @escaping (Issue) -> Future<Void>) throws {
		// TODO: I'm 99% sure this handles things concurrently, but I should check
		try Repository.shared.read(query.fetchAll)
			.traverse { issue in
				Self.issuePatchLimiter.dispatch { upload(issue) }
			}
			.await()
	}
}

extension Client {
	/// ensures local changes are pushed first
	func pullRemoteChanges() -> Future<Void> {
		pushChangesThen {
			try self.doPullRemoteChanges().await()
			Repository.shared.downloadMissingFiles()
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
	
	private func doPullRemoteChanges() -> Future<Void> {
		[
			doPullChangedObjects(existing: ConstructionManager.all(), context: ())
				.ignoringValue()
				.map { self.localUser = Repository.shared.object(self.localUser!.id) },
			doPullChangedObjects(existing: ConstructionSite.none(), context: ())
				.flatMap { $0.traverse(self.doPullRemoteChanges(for:)) }
		].sequence()
	}
	
	private func doPullChangedSites() -> Future<[ConstructionSite]> {
		send(GetObjectsRequest<ConstructionSite>())
			.map { $0.members.map { $0.makeObject() } }
	}
	
	private func doPullChangedObjects<Object: StoredObject>(
		for site: ConstructionSite? = nil,
		existing: QueryInterfaceRequest<Object>,
		context: Object.Model.Context
	) -> Future<[Object]> {
		send(GetObjectsRequest<Object>(
			constructionSite: site?.id,
			minLastChangeTime: existing.maxLastChangeTime()
		))
		.map { $0.members.map { $0.makeObject(context: context) } }
		.map { $0 <- { Repository.shared.update(changing: $0) } }
	}
	
	private func doPullRemoteChanges(for site: ConstructionSite) -> Future<Void> {
		guard site.managers.contains(localUser!.id) else {
			Repository.shared.ensureNotPresent(site)
			return .fulfilled
		}
		
		return [
			doPullChangedObjects(for: site, existing: site.maps, context: site.id)
				.ignoringValue(),
			doPullChangedObjects(for: site, existing: site.craftsmen, context: site.id)
				.ignoringValue(),
		]
		.sequence() // insert issues only after maps & craftsmen to keep intact foreign key constraints
		.flatMap { self.doPullChangedIssues(for: site) }
	}
	
	private func doPullChangedIssues(
		for site: ConstructionSite,
		itemsPerPage: Int = 100,
		prevLastChangeTime: Date? = nil
	) -> Future<Void> {
		// detect loops (making the same request multiple times) and respond by asking for larger pages
		let lastChangeTime = site.issues.maxLastChangeTime()
		let itemsPerPage = lastChangeTime != prevLastChangeTime ? itemsPerPage : itemsPerPage * 2
		
		return send(GetPagedObjectsRequest<APIIssue>(
			constructionSite: site.id,
			minLastChangeTime: lastChangeTime,
			itemsPerPage: itemsPerPage
		))
		.flatMap { collection in
			let issues = collection.members.map { $0.makeObject(context: site.id) }
			Repository.shared.update(changing: issues)
			
			return collection.view.nextPage == nil
				? .fulfilled
				: self.doPullChangedIssues(for: site, itemsPerPage: itemsPerPage, prevLastChangeTime: lastChangeTime)
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
