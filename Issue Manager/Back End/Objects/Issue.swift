// Created by Julian Dunskus

import Foundation
import GRDB
import UserDefault

struct Issue: Equatable {
	@MainActor
	static var isInClientMode: Bool {
		ViewOptions.shared.isInClientMode
	}
	
	private(set) var meta: Meta
	let constructionSiteID: ConstructionSite.ID
	let mapID: Map.ID
	
	let number: Int?
	var wasAddedWithClient: Bool { // "abnahmemodus"
		didSet {
			guard wasAddedWithClient != oldValue else { return }
			patch.wasAddedWithClient = wasAddedWithClient
		}
	}
	let deadline: Date?
	
	var isUnplaced: Bool { position == nil }
	var position: Position? {
		didSet {
			guard position != oldValue else { return }
			patch.position = position
		}
	}
	var isMarked = false {
		didSet {
			guard isMarked != oldValue else { return }
			patch.isMarked = isMarked
		}
	}
	var description: String? {
		didSet {
			guard description != oldValue else { return }
			patch.description = description
		}
	}
	var craftsmanID: Craftsman.ID? {
		didSet {
			guard craftsmanID != oldValue else { return }
			patch.craftsmanID = craftsmanID
		}
	}
	
	private(set) var status: Status
	
	var image: File<Issue>? {
		didSet {
			guard image != oldValue else { return }
			didChangeImage = true
		}
	}
	
	var lastChangeTime: Date {
		get { meta.lastChangeTime }
		set { meta.lastChangeTime = newValue }
	}
	
	// unsync change tracking
	private(set) var wasUploaded: Bool
	var didChangeImage = false
	var didDelete = false
	private(set) var patchIfChanged: IssuePatch?
	private var patch: IssuePatch {
		get { patchIfChanged ?? .init() }
		set { patchIfChanged = newValue }
	}
	
	struct Position: Equatable, Codable, DBRecord {
		var point: Point
		var zoomScale: Double
		
		var x: Double { point.x }
		var y: Double { point.y }
		
		init(at point: Point, zoomScale: Double) {
			self.point = point
			self.zoomScale = zoomScale
		}
	}
	
	struct Status: Equatable, Codable, DBRecord {
		var createdAt = Date()
		var createdBy: ConstructionManager.ID
		var registeredAt: Date?
		var registeredBy: ConstructionManager.ID?
		var resolvedAt: Date?
		var resolvedBy: Craftsman.ID?
		var closedAt: Date?
		var closedBy: ConstructionManager.ID?
		
		var simplified: Simplified {
			if closedAt != nil {
				return .closed
			} else if resolvedAt != nil {
				return .resolved
			} else if registeredAt != nil {
				return .registered
			} else {
				return .new
			}
		}
		
		/// a simplified representation of the status
		enum Simplified: Int, Codable, CaseIterable {
			case new, registered, resolved, closed
		}
		
		enum Columns {
			static let createdAt = Column(CodingKeys.createdAt)
			static let resolvedAt = Column(CodingKeys.resolvedAt)
			static let closedAt = Column(CodingKeys.closedAt)
		}
	}
}

extension Issue: StoredObject {
	typealias Model = APIIssue
	static let apiType = "issues"
}

extension Issue: FileContainer {
	static let pathPrefix = "issue"
	var file: File<Issue>? { image }
	
	private static let autoDownloadThreshold = Date(timeIntervalSinceNow: -3600 * 24 * 90) // 90 days
	
	var shouldAutoDownloadFile: Bool {
		guard !didChangeImage, let closedAt = status.closedAt else { return true }
		return closedAt > Self.autoDownloadThreshold
	}
}

extension Issue {
	@MainActor
	init(at position: Position? = nil, in map: Map, by author: ConstructionManager) {
		self.meta = .init()
		self.constructionSiteID = map.constructionSiteID
		self.mapID = map.id
		
		self.position = position
		self.number = nil
		self.wasAddedWithClient = Self.isInClientMode
		self.deadline = nil
		
		self.wasUploaded = false
		
		self.status = .init(createdBy: author.id)
		
		patch.wasAddedWithClient = wasAddedWithClient
		
		patch.createdAt = status.createdAt
		patch.createdBy = status.createdBy
		
		patch.constructionSiteID = constructionSiteID
		patch.mapID = mapID
		
		patch.position = position
	}
}

extension Issue: DBRecord {
	static let map = belongsTo(Map.self)
	var map: Map.Query {
		request(for: Self.map)
	}
	
	static let site = belongsTo(ConstructionSite.self)
	var site: ConstructionSite.Query {
		request(for: Self.site)
	}
	
	func craftsman(in db: Database) throws -> Craftsman? {
		try craftsmanID?.get(in: db)
	}
	
	func encode(to container: inout PersistenceContainer) throws {
		try meta.encode(to: &container)
		container[Columns.constructionSiteID] = constructionSiteID
		container[Columns.mapID] = mapID
		
		container[Columns.number] = number
		container[Columns.wasAddedWithClient] = wasAddedWithClient
		container[Columns.deadline] = deadline
		
		try container.encode(position, forKey: Columns.position)
		container[Columns.isMarked] = isMarked
		container[Columns.description] = description
		container[Columns.craftsmanID] = craftsmanID
		
		container[Columns.image] = image
		
		container[Columns.wasUploaded] = wasUploaded
		container[Columns.didChangeImage] = didChangeImage
		container[Columns.didDelete] = didDelete
		try container.encode(patchIfChanged, forKey: Columns.patchIfChanged)
		
		try status.encode(to: &container)
	}
	
	init(row: Row) throws {
		meta = try .init(row: row)
		constructionSiteID = row[Columns.constructionSiteID]
		mapID = row[Columns.mapID]
		
		number = row[Columns.number]
		wasAddedWithClient = row[Columns.wasAddedWithClient]
		deadline = row[Columns.deadline]
		
		position = try row.decodeValueIfPresent(forKey: Columns.position)
		isMarked = row[Columns.isMarked]
		description = row[Columns.description]
		craftsmanID = row[Columns.craftsmanID]
		
		image = row[Columns.image]
		
		wasUploaded = row[Columns.wasUploaded]
		didChangeImage = row[Columns.didChangeImage]
		didDelete = row[Columns.didDelete]
		patchIfChanged = try row.decodeValueIfPresent(forKey: Columns.patchIfChanged)
		
		status = try .init(row: row)
	}
	
	enum Columns: String, ColumnExpression {
		case constructionSiteID
		case mapID
		
		case number
		case wasAddedWithClient
		case deadline
		
		case position
		case isMarked
		case description
		case craftsmanID
		
		case image
		
		case wasUploaded
		case didChangeImage
		case didDelete
		case patchIfChanged
	}
}

extension DerivableRequest<Issue> {
	@MainActor
	var consideringClientMode: Self {
		Issue.isInClientMode ? filter(Issue.Columns.wasAddedWithClient) : self
	}
	
	var openIssues: Self {
		filter(Issue.Status.Columns.resolvedAt == nil && Issue.Status.Columns.closedAt == nil)
	}
	
	var issuesToInspect: Self {
		filter(Issue.Status.Columns.resolvedAt != nil && Issue.Status.Columns.closedAt == nil)
	}
}

// MARK: -
// MARK: Status
extension Issue {
	var isRegistered: Bool {
		status.registeredAt != nil
	}
	
	var isResolved: Bool {
		status.resolvedAt != nil
	}
	
	/// - note: does _not_ imply `hasResponse`!
	var isClosed: Bool {
		status.closedAt != nil
	}
	
	var isOpen: Bool {
		!isResolved && !isClosed
	}
}

// MARK: -
// MARK: Mutation
@MainActor
extension Issue {
	mutating func close(as author: ConstructionManager) {
		assert(isRegistered)
		assert(!isClosed)
		
		let now = Date()
		status.closedAt = now
		status.closedBy = author.id
		patch.closedAt = now
		patch.closedBy = author.id
	}
	
	mutating func reopen() {
		assert(isRegistered)
		assert(isClosed)
		
		status.closedAt = nil
		status.closedBy = nil
		patch.closedAt = nil
		patch.closedBy = nil
	}
	
	mutating func revertResolution() {
		assert(isResolved)
		assert(!isClosed)
		
		status.resolvedAt = nil
		status.resolvedBy = nil
		patch.resolvedAt = nil
		patch.resolvedBy = nil
	}
	
	mutating func delete() {
		meta.isDeleted = true
		didDelete = true
	}
	
	mutating func undelete() {
		meta.isDeleted = false
		didDelete = false
	}
	
	mutating func discardChangePatch() {
		patchIfChanged = nil
	}
	
	/// - returns: a closure that syncs any changes to the server, if desired
	func saveChanges(in repository: Repository) -> @Sendable (SyncManager) async throws -> Void {
		if isDeleted {
			guard wasUploaded else {
				repository.remove(self)
				return { _ in }
			}
		}
		repository.save(self)
		return { try await $0.pushLocalChanges() }
	}
}

struct Point: Equatable, Codable {
	var x: Double
	var y: Double
}
