// Created by Julian Dunskus

import Foundation
import GRDB

struct Issue {
	// NB: update `update(from:)` when adding/removing stored properties!
	let meta: ObjectMeta<Issue>
	let number: Int?
	let wasAddedWithClient: Bool // "abnahmemodus"
	let mapID: ID<Map> // only really used before registration
	let position: Position?
	private(set) var status = Status()
	private(set) var details = Details()
	
	var isMarked: Bool { return details.isMarked }
	var image: File? { return details.image }
	var description: String? { return details.description }
	var craftsmanID: ID<Craftsman>? { return details.craftsman }
	
	struct Details: Codable {
		var isMarked = false
		var image: File?
		var description: String?
		var craftsman: ID<Craftsman>?
	}
	
	struct Position: Codable {
		var point: Point
		var zoomScale: Double
		var mapFileID: ID<File>
		
		init(at point: Point, zoomScale: Double, in file: File) {
			self.point = point
			self.zoomScale = zoomScale
			self.mapFileID = file.id
		}
	}
	
	struct Status: Codable {
		/// registration in issue collection
		var registration: Event?
		/// response from craftsman
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
	}
}

extension Issue: DBRecord {
	static let map = belongsTo(Map.self)
	var map: QueryInterfaceRequest<Map> {
		return request(for: Issue.map)
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		container[Columns.number] = number
		container[Columns.wasAddedWithClient] = wasAddedWithClient
		container[Columns.mapID] = mapID
		if let position = position {
			try! container.encode(position, forKey: Columns.position)
		}
		try! container.encode(status, forKey: Columns.status)
		try! container.encode(details, forKey: Columns.details)
	}
	
	init(row: Row) {
		meta = .init(row: row)
		number = row[Columns.number]
		wasAddedWithClient = row[Columns.wasAddedWithClient]
		mapID = row[Columns.mapID]
		position = try! row.decodeValueIfPresent(forKey: Columns.position)
		status = try! row.decodeValue(forKey: Columns.status)
		details = try! row.decodeValue(forKey: Columns.details)
	}
	
	enum Columns: String, ColumnExpression {
		case number
		case wasAddedWithClient
		case mapID
		case position
		case status
		case details
	}
}

extension Issue: StoredObject {}

extension Issue: FileContainer {
	static let pathPrefix = "issue"
	static let downloadRequestPath = \FileDownloadRequest.issue
	var file: File? { return details.image }
}

// MARK: -
// MARK: Status
extension Issue {
	var isRegistered: Bool {
		return status.registration != nil
	}
	
	var hasResponse: Bool {
		return status.response != nil
	}
	
	/// - note: does _not_ imply `hasResponse`!
	var isReviewed: Bool {
		return status.review != nil
	}
	
	var isOpen: Bool {
		return status.review == nil
	}
}

// MARK: -
// MARK: Mutation
extension Issue {
	mutating func change(notifyingServer: Bool = true, transform: (inout Details) throws -> Void) rethrows {
		assert(!isRegistered)
		
		let oldFile = file
		try transform(&details)
		Client.shared.issueChanged(self, hasChangedFile: file != oldFile)
		
		Repository.shared.save(self)
	}
	
	mutating func mark() {
		details.isMarked.toggle()
		Client.shared.performed(.mark, on: self)
		
		Repository.shared.save(self)
	}
	
	mutating func review() {
		assert(isRegistered)
		assert(!isReviewed)
		
		status.review = .init(at: Date(), by: Client.shared.localUser!.user.fullName)
		Client.shared.performed(.review, on: self)
		
		Repository.shared.save(self)
	}
	
	mutating func revertReview() {
		assert(isReviewed)
		
		status.review = nil
		Client.shared.performed(.revert, on: self)
		
		Repository.shared.save(self)
	}
	
	mutating func revertResponse() {
		assert(hasResponse)
		assert(!isReviewed)
		
		status.response = nil
		Client.shared.performed(.revert, on: self)
		
		Repository.shared.save(self)
	}
}
