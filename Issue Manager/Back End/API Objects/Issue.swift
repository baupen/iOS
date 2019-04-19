// Created by Julian Dunskus

import Foundation

struct Issue {
	// NB: update `update(from:)` when adding/removing stored properties!
	let meta: ObjectMeta<Issue>
	let number: Int?
	let wasAddedWithClient: Bool // "abnahmemodus"
	let map: ID<Map> // only really used before registration
	let position: Position?
	private(set) var status = Status()
	private(set) var details = Details()
	
	var isMarked: Bool { return details.isMarked }
	var image: File? { return details.image }
	var description: String? { return details.description }
	var craftsman: ID<Craftsman>? { return details.craftsman }
	
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
		self.map = map.id
		self.position = position
	}
}

extension Issue: APIObject {
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: Key.self)
		
		try meta = container.decodeValue(forKey: .meta)
		try number = container.decodeValue(forKey: .number)
		try wasAddedWithClient = container.decodeValue(forKey: .wasAddedWithClient)
		try map = container.decodeValue(forKey: .map)
		try position = container.decodeValue(forKey: .position)
		try status = container.decodeValue(forKey: .status)
		
		try details = Details(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: Key.self)
		
		try container.encode(meta, forKey: .meta)
		try container.encode(number, forKey: .number)
		try container.encode(wasAddedWithClient, forKey: .wasAddedWithClient)
		try container.encode(map, forKey: .map)
		try container.encode(position, forKey: .position)
		try container.encode(status, forKey: .status)
		
		try details.encode(to: encoder)
	}
	
	enum Key: CodingKey {
		case meta
		case number
		case wasAddedWithClient
		case map
		case position
		case status
	}
}

extension Issue: FileContainer {
	static let pathPrefix = "issue"
	static let downloadRequestPath = \FileDownloadRequest.issue
	var file: File? { return details.image }
}

extension Issue {
	func accessCraftsman() -> Craftsman? {
		return craftsman.flatMap(Repository.shared.craftsman)
	}
	
	func accessMap() -> Map {
		return Repository.shared.map(map)!
	}
}

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
