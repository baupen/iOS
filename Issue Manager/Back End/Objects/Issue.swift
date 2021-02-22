// Created by Julian Dunskus

import Foundation
import GRDB

struct Issue {
	private(set) var meta: Meta
	let constructionSiteID: ConstructionSite.ID
	let mapID: Map.ID?
	
	let number: Int?
	let wasAddedWithClient: Bool // "abnahmemodus"
	let deadline: Date?
	
	let position: Position?
	var isMarked = false {
		didSet { patch.isMarked = .some(isMarked) }
	}
	var description: String? {
		didSet { patch.description = .some(description) }
	}
	var craftsmanID: Craftsman.ID? {
		didSet { patch.craftsman = .some(craftsmanID) }
	}
	
	private(set) var status: Status
	
	var image: File<Issue>? {
		didSet { didChangeImage = true }
	}
	
	private(set) var wasUploaded: Bool
	private(set) var didChangeImage = false
	private(set) var patchIfChanged: IssuePatch?
	private var patch: IssuePatch {
		get { patchIfChanged ?? .init() }
		set { patchIfChanged = newValue }
	}
	
	struct Position: Codable, DBRecord {
		var point: Point
		var zoomScale: Double
		
		init(at point: Point, zoomScale: Double) {
			self.point = point
			self.zoomScale = zoomScale
		}
	}
	
	struct Status: Codable, DBRecord {
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
				return .reviewed
			} else if resolvedAt != nil {
				return .responded
			} else if registeredAt != nil {
				return .registered
			} else {
				return .new
			}
		}
		
		/// a simplified representation of the status
		enum Simplified: Int, Codable, CaseIterable {
			case new, registered, responded, reviewed
		}
		
		enum Columns {
			static let closedAt = Column(CodingKeys.closedAt)
			static let resolvedAt = Column(CodingKeys.resolvedAt)
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
}

extension Issue {
	init(at position: Position? = nil, in map: Map) {
		self.meta = .init()
		self.constructionSiteID = map.constructionSiteID
		self.mapID = map.id
		
		self.position = position
		self.number = nil
		self.wasAddedWithClient = defaults.isInClientMode
		self.deadline = nil
		
		self.wasUploaded = false
		
		self.status = .init(createdBy: Client.shared.localUser!.id)
	}
}

extension Issue: DBRecord {
	static let map = belongsTo(Map.self)
	var map: QueryInterfaceRequest<Map> {
		request(for: Self.map)
	}
	
	static let site = belongsTo(ConstructionSite.self)
	var site: QueryInterfaceRequest<ConstructionSite> {
		request(for: Self.site)
	}
	
	func craftsman(in db: Database) throws -> Craftsman? {
		try craftsmanID?.get(in: db)
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		container[Columns.constructionSiteID] = constructionSiteID
		container[Columns.mapID] = mapID
		
		container[Columns.number] = number
		container[Columns.wasAddedWithClient] = wasAddedWithClient
		container[Columns.deadline] = deadline
		
		try! container.encode(position, forKey: Columns.position)
		container[Columns.isMarked] = isMarked
		container[Columns.description] = description
		container[Columns.craftsmanID] = craftsmanID
		
		container[Columns.wasUploaded] = wasUploaded
		container[Columns.didChangeImage] = didChangeImage
		try! container.encode(patchIfChanged, forKey: Columns.patchIfChanged)
		
		status.encode(to: &container)
	}
	
	init(row: Row) {
		meta = .init(row: row)
		constructionSiteID = row[Columns.constructionSiteID]
		mapID = row[Columns.mapID]
		
		number = row[Columns.number]
		wasAddedWithClient = row[Columns.wasAddedWithClient]
		deadline = row[Columns.deadline]
		
		position = try! row.decodeValueIfPresent(forKey: Columns.position)
		isMarked = row[Columns.isMarked]
		description = row[Columns.description]
		craftsmanID = row[Columns.craftsmanID]
		
		image = row[Columns.image]
		
		wasUploaded = row[Columns.wasUploaded]
		didChangeImage = row[Columns.didChangeImage]
		patchIfChanged = try! row.decodeValueIfPresent(forKey: Columns.patchIfChanged)
		
		status = .init(row: row)
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
		case patchIfChanged
	}
}

extension DerivableRequest where RowDecoder == Issue {
	var consideringClientMode: Self {
		defaults.isInClientMode ? filter(Issue.Columns.wasAddedWithClient) : self
	}
	
	var openIssues: Self {
		filter(Issue.Status.Columns.closedAt == nil)
	}
	
	var issuesWithResponse: Self {
		filter(Issue.Status.Columns.resolvedAt != nil)
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
		status.closedAt == nil
	}
}

// MARK: -
// MARK: Mutation
extension Issue {
	mutating func close() {
		assert(isRegistered)
		assert(isOpen)
		
		let now = Date()
		let author = Client.shared.localUser!.id
		status.closedAt = now
		status.closedBy = author
		patch.closedAt = .some(now)
		patch.closedBy = .some(author)
	}
	
	mutating func reopen() {
		assert(isRegistered)
		assert(isClosed)
		
		status.closedAt = nil
		status.closedBy = nil
		patch.closedAt = .some(nil)
		patch.closedBy = .some(nil)
	}
	
	mutating func revertResolution() {
		assert(isResolved)
		assert(isOpen)
		
		status.resolvedAt = nil
		status.resolvedBy = nil
		patch.resolvedAt = .some(nil)
		patch.resolvedBy = .some(nil)
	}
	
	mutating func delete() {
		meta.isDeleted = true
	}
	
	func saveAndSync() {
		Repository.shared.save(self)
		_ = Client.shared.pushLocalChanges()
	}
}
