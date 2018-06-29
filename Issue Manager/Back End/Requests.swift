// Created by Julian Dunskus

import Foundation

extension Client {
	fileprivate func getUser() -> Future<User> {
		return user.map(Future.fulfilled) ?? .rejected(with: RequestError.notAuthenticated)
	}
}

extension Future {
	func ignoringResult() -> Future<Void> {
		return self.map { _ in }
	}
}

fileprivate func logOutcome<T>(of future: Future<T>, as method: String) {
	future.then { _ in
		print("\(method) completed successfully")
	}
	
	future.catch { error in
		print("\(method) encountered error:")
		print(error.localizedDescription)
		dump(error)
	}
}

// MARK: -
// MARK: Log In

struct LoginRequest: JSONJSONRequest {
	static let isIndependent = true
	
	var method: String { return "login" }
	
	let username: String
	let passwordHash: String
	let clientVersion = 1
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.user = response.user <- {
			$0.username = username // TODO remove once API updated
			$0.passwordHash = passwordHash
		}
		Client.shared.saveShared()
	}
	
	struct ExpectedResponse: Response {
		let user: User
	}
}

extension Client {
	func logIn(as username: String, password: String) -> Future<Void> {
		let request = LoginRequest(
			username: username,
			passwordHash: password.sha256()
		)
		return Client.shared.send(request).ignoringResult()
	}
}

// MARK: -
// MARK: Read

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
		func updateEntries<T: APIObject>(in path: WritableKeyPath<Storage, [UUID: T]>,
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
		
		updateEntries(in: \.craftsmen, changing: response.changedCraftsmen, removing: response.removedCraftsmanIDs)
		updateEntries(in: \.buildings, changing: response.changedBuildings, removing: response.removedBuildingIDs)
		updateEntries(in: \.maps,      changing: response.changedMaps,      removing: response.removedMapIDs)
		updateEntries(in: \.issues,    changing: response.changedIssues,    removing: response.removedIssueIDs)
		
		if let newUser = response.changedUser {
			user = newUser
		}
		
		saveShared()
	}
}

// MARK: -
// MARK: File Download

typealias DownloadRequestPath = WritableKeyPath<FileDownloadRequest, ObjectMeta?>

struct FileDownloadRequest: JSONDataRequest {
	static let isIndependent = true
	
	var method: String { return "file/download" }
	
	// mutable for keypath stuff
	private(set) var authenticationToken: String
	private(set) var building: ObjectMeta? = nil
	private(set) var map: ObjectMeta? = nil
	private(set) var issue: ObjectMeta? = nil
	
	init(authenticationToken: String, requestingFileFor path: DownloadRequestPath, meta: ObjectMeta) {
		self.authenticationToken = authenticationToken
		self[keyPath: path] = meta
	}
}

extension Client {
	func downloadFile(for path: DownloadRequestPath, meta: ObjectMeta) -> Future<Data> {
		return getUser()
			.map { user in
				FileDownloadRequest(
					authenticationToken: user.authenticationToken,
					requestingFileFor: path,
					meta: meta
				)
			}.flatMap(Client.shared.send)
	}
}

// MARK: -
// MARK: Issue Creation

struct IssueCreationRequest: MultipartJSONRequest, BacklogStorable {
	static let storageID = "issue creation"
	
	static let isIndependent = false
	
	var method: String { return "issue/create" }
	
	let authenticationToken: String
	let issue: Issue
	let fileURL: URL?
	
	func applyToClient(_ response: ExpectedResponse) {
		let previous = Client.shared.storage.issues[issue.id]
		Client.shared.storage.issues[issue.id] = response.issue
		response.issue.downloadFile(previous: previous)
		Client.shared.saveShared()
	}
	
	struct ExpectedResponse: Response {
		let issue: Issue
	}
}

extension Client {
	func issueCreated(_ issue: Issue) {
		let result = getUser()
			.map { user in
				IssueCreationRequest(
					authenticationToken: user.authenticationToken,
					issue: issue,
					fileURL: issue.filename.map(Issue.localURL)
				)
			}.flatMap(Client.shared.send)
		
		logOutcome(of: result, as: "issue creation")
	}
}

// MARK: -
// MARK: Issue Update

struct IssueUpdateRequest: MultipartJSONRequest, BacklogStorable {
	static let storageID = "issue update"
	
	static let isIndependent = false
	
	var method: String { return "issue/update" }
	
	let authenticationToken: String
	let issue: Issue
	let fileURL: URL?
	
	func applyToClient(_ response: ExpectedResponse) {
		let previous = Client.shared.storage.issues[issue.id]
		Client.shared.storage.issues[issue.id] = response.issue
		response.issue.downloadFile(previous: previous)
		Client.shared.saveShared()
	}
	
	struct ExpectedResponse: Response {
		let issue: Issue
	}
}

extension Client {
	func issueChanged(_ issue: Issue, hasChangedFilename: Bool) {
		let result = getUser()
			.map { user in
				IssueUpdateRequest(
					authenticationToken: user.authenticationToken,
					issue: issue,
					fileURL: issue.filename.map(Issue.localURL)
				)
			}.flatMap(Client.shared.send)
		
		logOutcome(of: result, as: "issue update")
	}
}

// MARK: -
// MARK: Issue Deletion

struct IssueDeletionRequest: JSONJSONRequest, BacklogStorable {
	static let storageID = "issue deletion"
	
	static let isIndependent = false
	
	var method: String { return "issue/delete" }
	
	let authenticationToken: String
	let issueID: UUID
	
	func applyToClient(_ response: ExpectedResponse) {
		Client.shared.storage.issues[issueID]?.deleteFile()
		Client.shared.storage.issues[issueID] = nil
		Client.shared.saveShared()
	}
	
	typealias ExpectedResponse = EmptyCollection<Void>
}

extension EmptyCollection: Response {
	public init(from decoder: Decoder) throws {
		self.init()
	}
}

extension Client {
	func issueRemoved(_ issue: Issue) {
		let result = getUser()
			.map { user in
				IssueDeletionRequest(
					authenticationToken: user.authenticationToken,
					issueID: issue.id
				)
			}.flatMap(Client.shared.send)
		
		logOutcome(of: result, as: "issue deletion")
	}
}

// MARK: -
// MARK: Issue Actions

enum IssueAction: String, Codable {
	case mark
	case review
	case revert
}

struct IssueActionRequest: JSONJSONRequest, BacklogStorable {
	static let storageID = "issue action"
	static let isIndependent = false
	
	var method: String { return "issue/\(action.rawValue)" }
	
	let authenticationToken: String
	let issueID: UUID
	let action: IssueAction
	
	func applyToClient(_ response: ExpectedResponse) {
		assert(issueID == response.issue.id)
		Client.shared.storage.issues[response.issue.id] = response.issue
		Client.shared.saveShared()
	}
	
	struct ExpectedResponse: Response {
		let issue: Issue
	}
}

extension Client {
	func performed(_ action: IssueAction, on issue: Issue) {
		let result = getUser()
			.map { user in
				IssueActionRequest(
					authenticationToken: user.authenticationToken,
					issueID: issue.id,
					action: action
				)
			}.flatMap(Client.shared.send)
		
		logOutcome(of: result, as: "issue \(action.rawValue)")
	}
}
