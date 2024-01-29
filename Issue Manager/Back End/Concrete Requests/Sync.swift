// Created by Julian Dunskus

import Foundation
import GRDB
import HandyOperators

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

final actor SyncManager {
	static let shared = SyncManager()
	
	private init() {}
	
	private var currentTask: (() async -> Void)?
	/// waits for there to be no running task, then runs the given block
	private func withoutReentrancy<Result: Sendable>(
		run block: @escaping (isolated SyncManager) async throws -> Result
	) async throws -> Result {
		while let currentTask {
			print("waiting for opening...")
			await currentTask()
		}
		print("running block!")
		// block can't actually escape, but withoutActuallyEscaping doesn't play nice with actor isolation as of Xcode 15.1
		let task = Task {
			// this is the best place to safely nil out currentTask, since places awaiting the task may resume in any order
			defer { self.currentTask = nil }
			return try await block(self)
		}
		let wait = { _ = await task.result }
		currentTask = wait
		return try await task.value
	}
	
	/// runs the given block once any in-progress syncing has completed, to avoid bad interleavings
	func withContext(run block: @escaping @Sendable (SyncContext) async throws -> Void) async throws {
		try await withoutReentrancy { _ in
			try await block(SyncContext(client: .shared))
		}
	}
	
	func pushLocalChanges() async throws {
		try await withContext {
			try await $0.pushLocalChanges()
		}
	}
}

struct SyncContext {
	var requestContext: RequestContext
	var progressHandler: ProgressHandler<SyncProgress> = .ignore
	var issueImageProgressHandler: ProgressHandler<FileDownloadProgress> = .ignore
	
	@MainActor
	fileprivate init(client: Client) {
		self.requestContext = client.makeContext()
	}
	
	func onProgress(_ handler: ProgressHandler<SyncProgress>) -> Self {
		self <- { $0.progressHandler = handler }
	}
	
	func onIssueImageProgress(_ handler: ProgressHandler<FileDownloadProgress>) -> Self {
		self <- { $0.issueImageProgressHandler = handler }
	}
	
	fileprivate func send<R: Request>(_ request: R) async throws -> R.Response {
		try await requestContext.send(request)
	}
}

extension SyncContext {
	func pushLocalChanges() async throws {
		let errors = try await tryPushLocalChanges()
		guard errors.isEmpty else {
			throw RequestError.pushFailed(errors)
		}
	}
	
	private func tryPushLocalChanges() async throws -> [IssuePushError] {
		let maxLastChangeTime = Issue.all().maxLastChangeTime()
		
		let issuesWithPatches = Issue
			.filter(Issue.Columns.patchIfChanged != nil)
			.order(Issue.Status.Columns.createdAt)
		let patchErrors = try await syncChanges(
			for: issuesWithPatches,
			stage: .patch
		) { issue in
			let canonical = try await self.syncPatch(for: issue)
			Repository.shared.remove(issue) // remove non-canonical copy
			Repository.shared.save(canonical <- {
				// keep local changes to image to sync next (this sets didChangeImage relative to remote image)
				$0.image = issue.image
				// fake older last change time to avoid skipping changes between last max change time and this upload
				$0.lastChangeTime = maxLastChangeTime
			})
		}
		
		guard patchErrors.isEmpty else { return patchErrors }
		
		let imageErrors = try await syncChanges(
			for: Issue.filter(Issue.Columns.didChangeImage).withoutDeleted,
			stage: .imageUpload
		) { issue in
			try await self.syncImageChange(for: issue)
			Repository.shared.save(
				[.didChangeImage],
				of: issue <- { $0.didChangeImage = false }
			)
		}
		
		let deletionErrors = try await syncChanges(
			for: Issue.filter(Issue.Columns.didDelete),
			stage: .deletion
		) { issue in
			try await send(DeletionRequest(for: issue))
			Repository.shared.save(
				[.didDelete],
				of: issue <- { $0.didDelete = false }
			)
		}
		
		return imageErrors + deletionErrors
	}
	
	private func syncPatch(for issue: Issue) async throws -> Issue {
		let patch = issue.patchIfChanged!.makeModel()
		let canonical = try await issue.wasUploaded
			? send(IssuePatchRequest(path: issue.apiPath, body: patch))
			: send(IssueCreationRequest(body: patch))
		return canonical.makeObject(context: issue.constructionSiteID)
	}
	
	private func syncImageChange(for issue: Issue) async throws {
		if let localImage = issue.image {
			let path = try await send(ImageUploadRequest(issue: issue, fileURL: Issue.localURL(for: localImage)))
			let image = File<Issue>(urlPath: path)
			try localImage.onUpload(as: image)
			Repository.shared.save([.image], of: issue <- { $0.image = image })
		} else {
			try await send(DeletionRequest(forImageOf: issue))
		}
	}
	
	private func syncChanges(
		for query: Issue.Query,
		stage: IssuePushError.Stage,
		performing upload: @escaping (Issue) async throws -> Void
	) async throws -> [IssuePushError] {
		// no concurrency to ensure correct ordering and avoid unforeseen issues
		var errors: [IssuePushError] = []
		for issue in Repository.read(query.fetchAll) {
			do {
				try await upload(issue)
			} catch RequestError.communicationError(let error) {
				throw RequestError.communicationError(error) // cancel if connection interrupted
			} catch {
				errors.append(IssuePushError(stage: stage, cause: error, issue: issue))
			}
		}
		return errors
	}
}

struct IssuePushError: Error, Identifiable {
	let id = UUID()
	
	var stage: Stage
	var cause: Error
	var issue: Issue
	
	enum Stage: Equatable, CaseIterable {
		case patch
		case imageUpload
		case deletion
	}
}

enum SyncProgress {
	case pushingLocalChanges
	case fetchingTopLevelObjects
	case pullingSiteData(ConstructionSite)
	case downloadingConstructionSiteFiles(FileDownloadProgress)
	case downloadingMapFiles(FileDownloadProgress)
}

extension SyncContext {
	/// ensures local changes are pushed first
	func pullRemoteChanges() async throws {
		try await sync { onProgress in
			let sites = Repository.read(ConstructionSite.fetchAll)
			for site in sites {
				onProgress(.pullingSiteData(site))
				try await self.doPullRemoteChanges(for: site)
			}
		}
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges(for siteID: ConstructionSite.ID) async throws {
		try await sync { onProgress in
			guard let site = Repository.read(siteID.get)
			else { throw SyncError.siteAccessRemoved }
			onProgress(.pullingSiteData(site))
			try await self.doPullRemoteChanges(for: site)
		}
	}
	
	private static let fileDownloadQueue = DispatchQueue(label: "missing file downloads")
	private func sync(
		running block: @escaping @Sendable (ProgressHandler<SyncProgress>.Unisolated) async throws -> Void
	) async throws {
		try await progressHandler.unisolated { onProgress in
			onProgress(.pushingLocalChanges)
			try await pushLocalChanges() // reentrant version
			
			onProgress(.fetchingTopLevelObjects)
			try await doPullChangedTopLevelObjects()
			try await block(onProgress)
			
			// download important files now
			try await ConstructionSite.downloadMissingFiles(
				onProgress: onProgress.wrapped { .downloadingConstructionSiteFiles($0) }
			)
			try await Map.downloadMissingFiles(
				onProgress: onProgress.wrapped { .downloadingMapFiles($0) }
			)
		}
		
		// download issue images in the background
		Task.detached(priority: .utility) {
			try? await Issue.downloadMissingFiles(onProgress: issueImageProgressHandler)
		}
	}
	
	private func doPullChangedTopLevelObjects() async throws {
		try await doPullChangedObjects(existing: ConstructionManager.all(), context: ())
		let userID = await requestContext.client.updateLocalUser()!.id
		let sites = try await doPullChangedObjects(existing: ConstructionSite.none(), context: ())
		// remove sites we don't have access to
		sites
			.filter { !$0.managerIDs.contains(userID) }
			.forEach { Repository.shared.ensureNotPresent($0) }
	}
	
	@discardableResult
	private func doPullChangedObjects<Object: StoredObject>(
		for site: ConstructionSite? = nil,
		existing: Object.Query,
		context: Object.Model.Context
	) async throws -> [Object] {
		let collection = try await send(GetObjectsRequest<Object>(
			constructionSite: site?.id,
			minLastChangeTime: existing.maxLastChangeTime()
		))
		let objects = collection.makeObjects(context: context)
		Repository.shared.update(changing: objects)
		return objects
	}
	
	private func doPullRemoteChanges(for site: ConstructionSite) async throws {
		try await doPullChangedObjects(for: site, existing: site.maps, context: site.id)
		try await doPullChangedObjects(for: site, existing: site.craftsmen, context: site.id)
		// insert issues only after maps & craftsmen to maintain foreign key constraints
		try await doPullChangedIssues(for: site)
	}
	
	private func doPullChangedIssues(for site: ConstructionSite) async throws {
		var itemsPerPage = 1000
		var lastChangeTime = Date.distantPast
		while true {
			// detect loops (making the same request multiple times) and respond by asking for larger pages
			let newTime = site.issues.maxLastChangeTime()
			if newTime == lastChangeTime {
				itemsPerPage *= 2
			} else {
				itemsPerPage = 1000
				lastChangeTime = newTime
			}
			
			let collection = try await send(GetPagedObjectsRequest<APIIssue>(
				constructionSite: site.id,
				minLastChangeTime: lastChangeTime,
				itemsPerPage: itemsPerPage
			))
			
			let issues = collection.makeObjects(context: site.id)
			Repository.shared.update(changing: issues)
			
			guard collection.view.nextPage != nil else { break } // done
		}
	}
}

enum SyncError: Error {
	case siteAccessRemoved
}

private extension QueryInterfaceRequest where RowDecoder: StoredObject {
	func maxLastChangeTime() -> Date {
		Repository.read(
			self
				.select(max(Issue.Meta.Columns.lastChangeTime), as: Date.self)
				.fetchOne
		) ?? .distantPast
	}
}

infix operator <-: WithPrecedence // resolve conflict between GRDB and HandyOperators
