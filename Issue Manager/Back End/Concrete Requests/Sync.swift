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

private struct ImageUploadRequest: MultipartEncodingRequest {
	var path: String
	
	var fileURL: URL
	
	var parts: [MultipartPart] {
		MultipartPart(name: "image", content: .jpeg(at: fileURL))
	}
	
	init(issue: Issue, fileURL: URL) {
		self.path = "\(issue.apiPath)/image"
		self.fileURL = fileURL
	}
	
	func decode(from data: Data, using decoder: JSONDecoder) throws -> String {
		try String(bytes: data, encoding: .utf8)
			??? ImageUploadError.invalidPathResponse
	}
	
	enum ImageUploadError: Error {
		case invalidPathResponse
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
	func pushLocalChanges() -> Future<Void> {
		pushChangesThen {}
	}
	
	func synchronouslyPushLocalChanges() throws {
		assertOnLinearQueue()
		
		let maxLastChangeTime = Issue.all().maxLastChangeTime()
		
		let issuesWithPatches = Issue
			.filter(Issue.Columns.patchIfChanged != nil)
			.order(Issue.Status.Columns.createdAt)
		try syncChanges(for: issuesWithPatches) { issue in
			self.syncPatch(for: issue).map {
				Repository.shared.remove(issue) // remove non-canonical copy
				Repository.shared.save($0 <- {
					// keep local changes to image to sync next (this sets didChangeImage relative to remote image)
					$0.image = issue.image
					// fake older last change time to avoid skipping changes between last max change time and this upload
					$0.lastChangeTime = maxLastChangeTime
				})
			}
		}
		
		try syncChanges(for: Issue.filter(Issue.Columns.didChangeImage)) { issue in
			self.syncImageChange(for: issue).map {
				Repository.shared.save(
					[.didChangeImage],
					of: issue <- { $0.didChangeImage = false }
				)
			}
		}
		
		try syncChanges(for: Issue.filter(Issue.Columns.didDelete)) { issue in
			self.send(DeletionRequest(for: issue)).map {
				Repository.shared.save(
					[.didDelete],
					of: issue <- { $0.didDelete = false }
				)
			}
		}
	}
	
	private func syncPatch(for issue: Issue) -> Future<Issue> {
		let patch = issue.patchIfChanged!.makeModel()
		let canonical = issue.wasUploaded
			? send(IssuePatchRequest(path: issue.apiPath, body: patch))
			: send(IssueCreationRequest(body: patch))
		return canonical.map { $0.makeObject(context: issue.constructionSiteID) }
	}
	
	private func syncImageChange(for issue: Issue) -> Future<Void> {
		issue.image
			.map {
				send(ImageUploadRequest(issue: issue, fileURL: Issue.localURL(for: $0))).map { path in
					let image = File<Issue>(urlPath: path)
					issue.fileUploaded(to: image)
					Repository.shared.save([.image], of: issue <- { $0.image = image })
				}
			}
			?? send(DeletionRequest(forImageOf: issue))
	}
	
	private func syncChanges(
		for query: QueryInterfaceRequest<Issue>,
		performing upload: @escaping (Issue) -> Future<Void>
	) throws {
		// no concurrency to ensure correct ordering and avoid unforeseen issues
		for issue in Repository.shared.read(query.fetchAll) {
			try upload(issue).await()
		}
	}
}

extension Client {
	/// ensures local changes are pushed first
	func pullRemoteChanges() -> Future<Void> {
		sync {
			try Repository.shared.read(ConstructionSite.fetchAll)
				.traverse(self.doPullRemoteChanges(for:))
				.await()
		}
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges(for siteID: ConstructionSite.ID) -> Future<Void> {
		sync {
			guard let site = Repository.shared.read(siteID.get)
			else { throw SyncError.siteAccessRemoved }
			try self.doPullRemoteChanges(for: site).await()
		}
	}
	
	private static let fileDownloadQueue = DispatchQueue(label: "missing file downloads")
	private func sync(running block: @escaping () throws -> Void) -> Future<Void> {
		pushChangesThen {
			try self.doPullChangedTopLevelObjects().await()
			try block()
			
			// download important files now
			try ConstructionSite.downloadMissingFiles().await()
			try Map.downloadMissingFiles().await()
			
			// download issue images in the background
			Self.fileDownloadQueue.async {
				try? Issue.downloadMissingFiles().await()
			}
		}
	}
	
	private func doPullChangedTopLevelObjects() -> Future<Void> {
		[
			doPullChangedObjects(existing: ConstructionManager.all(), context: ())
				.ignoringValue()
				.map { self.localUser = Repository.shared.object(self.localUser!.id) },
			doPullChangedObjects(existing: ConstructionSite.none(), context: ())
				// remove sites we don't have access to
				.map { $0
					.filter { !$0.managers.contains(self.localUser!.id) }
					.forEach { Repository.shared.ensureNotPresent($0) }
				}
		].sequence()
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
		[
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

enum SyncError: Error {
	case siteAccessRemoved
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
