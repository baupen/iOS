// Created by Julian Dunskus

import Foundation
import GRDB

struct Issue {
	let meta: ObjectMeta<Issue>
	let number: Int?
	let wasAddedWithClient: Bool // "abnahmemodus"
	let mapID: ID<Map> // only really used before registration
	let position: Position?
	private(set) var status = Status() {
		didSet { Repository.shared.save(self) }
	}
	private(set) var details = Details() {
		didSet { Repository.shared.save(self) }
	}
	private(set) var wasUploaded: Bool
	
	var isMarked: Bool { details.isMarked }
	var image: File<Issue>? { details.image }
	var description: String? { details.description }
	var craftsmanID: ID<Craftsman>? { details.craftsman }
	
	struct Details: Codable {
		var isMarked = false
		var image: File<Issue>?
		var description: String?
		var craftsman: ID<Craftsman>?
	}
	
	struct Position: Codable {
		var point: Point
		var zoomScale: Double
		var mapFileID: ID<File<Map>>
		
		init(at point: Point, zoomScale: Double, in file: File<Map>) {
			self.point = point
			self.zoomScale = zoomScale
			self.mapFileID = file.id
		}
	}
	
	struct Status: Codable {
		/// registration in issue collection
		var registration: Event?
		/// response from craftsman; might be nil even if reviewed
		var response: Event?
		/// review by supervisor
		var review: Event?
		
		var simplified: Simplified {
			if review != nil {
				return .reviewed
			} else if response != nil {
				return .responded
			} else if registration != nil {
				return .registered
			} else {
				return .new
			}
		}
		
		struct Event: Codable {
			var time: Date
			/// the name whoever caused the event chose
			var author: String
			
			init(at time: Date, by author: String) {
				self.time = time
				self.author = author
			}
		}
		
		/// a simplified representation of the status
		enum Simplified: Int, Codable, CaseIterable {
			case new, registered, responded, reviewed
		}
	}
}

extension Issue {
	init(at position: Position? = nil, in map: Map) {
		self.meta = .init()
		self.number = nil
		self.wasAddedWithClient = defaults.isInClientMode
		self.mapID = map.id
		self.position = position
		self.wasUploaded = false
	}
}

extension Issue: DBRecord {
	static let map = belongsTo(Map.self)
	var map: QueryInterfaceRequest<Map> {
		request(for: Issue.map)
	}
	
	var site: QueryInterfaceRequest<ConstructionSite> {
		ConstructionSite.joining(required: ConstructionSite.maps.filter(key: mapID))
	}
	
	func craftsman(in db: Database) throws -> Craftsman? {
		try craftsmanID?.get(in: db)
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		
		container[Columns.number] = number
		container[Columns.wasAddedWithClient] = wasAddedWithClient
		container[Columns.mapID] = mapID
		container[Columns.wasUploaded] = wasUploaded
		
		try! container.encode(position, forKey: Columns.position)
		try! container.encode(details, forKey: Columns.details)
		
		try! container.encode(status.registration, forKey: Columns.registration)
		try! container.encode(status.response, forKey: Columns.response)
		try! container.encode(status.review, forKey: Columns.review)
	}
	
	init(row: Row) {
		meta = .init(row: row)
		
		number = row[Columns.number]
		wasAddedWithClient = row[Columns.wasAddedWithClient]
		mapID = row[Columns.mapID]
		wasUploaded = row[Columns.wasUploaded]
		
		position = try! row.decodeValueIfPresent(forKey: Columns.position)
		details = try! row.decodeValue(forKey: Columns.details)
		
		status = .init(
			registration: try! row.decodeValueIfPresent(forKey: Columns.registration),
			response: try! row.decodeValueIfPresent(forKey: Columns.response),
			review: try! row.decodeValueIfPresent(forKey: Columns.review)
		)
	}
	
	enum Columns: String, ColumnExpression {
		case number
		case wasAddedWithClient
		case mapID
		case position
		case details
		case registration = "status.registration"
		case response = "status.response"
		case review = "status.review"
		case wasUploaded
	}
}

extension DerivableRequest where RowDecoder == Issue {
	var consideringClientMode: Self {
		defaults.isInClientMode ? filter(Issue.Columns.wasAddedWithClient) : self
	}
	
	var openIssues: Self {
		filter(Issue.Columns.review == nil)
	}
	
	var issuesWithResponse: Self {
		filter(Issue.Columns.response != nil)
	}
}

extension Issue: StoredObject {}

extension Issue: FileContainer {
	static let pathPrefix = "issue"
	static let downloadRequestPath = \FileDownloadRequest.issue
	var file: File<Issue>? { details.image }
}

// MARK: -
// MARK: Status
extension Issue {
	var isRegistered: Bool {
		status.registration != nil
	}
	
	var hasResponse: Bool {
		status.response != nil
	}
	
	/// - note: does _not_ imply `hasResponse`!
	var isReviewed: Bool {
		status.review != nil
	}
	
	var isOpen: Bool {
		status.review == nil
	}
}

// MARK: -
// MARK: Mutation
// TODO: At some point, change this stuff so you can mutate any issue as much as you want, but you just can't save it (without accessing the repository directly) without these kinds of methods. Would make the editor nicer; you could have an old and a new copy and bind to the new one (whenever SwiftUI becomes viable).
extension Issue {
	mutating func create(transform: (inout Details) throws -> Void) rethrows {
		assert(!isRegistered)
		
		try transform(&details)
		Client.shared.issueCreated(self)
	}
	
	mutating func change(transform: (inout Details) throws -> Void) rethrows {
		assert(!isRegistered)
		
		let oldFile = file
		try transform(&details)
		Client.shared.issueChanged(self, hasChangedFile: file != oldFile)
	}
	
	mutating func mark() {
		details.isMarked.toggle()
		Client.shared.performed(.mark, on: self)
	}
	
	mutating func review() {
		assert(isRegistered)
		assert(!isReviewed)
		
		status.review = .init(at: Date(), by: Client.shared.localUser!.user.fullName)
		Client.shared.performed(.review, on: self)
	}
	
	mutating func revertReview() {
		assert(isReviewed)
		
		status.review = nil
		Client.shared.performed(.revert, on: self)
	}
	
	mutating func revertResponse() {
		assert(hasResponse)
		assert(!isReviewed)
		
		status.response = nil
		Client.shared.performed(.revert, on: self)
	}
}
