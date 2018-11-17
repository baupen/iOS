// Created by Julian Dunskus

import Foundation

final class Issue: APIObject {
	// NB: update `update(from:)` when adding/removing stored properties!
	var meta = ObjectMeta<Issue>()
	var number: Int?
	var isMarked = false
	var wasAddedWithClient: Bool // "abnahmemodus"
	var imageFilename: String?
	var description: String?
	var craftsman: ID<Craftsman>?
	var map: ID<Map> // only really used before registration
	var status: Status = Status()
	var position: Position?
	
	init(at position: Position? = nil, in map: Map) {
		self.wasAddedWithClient = defaults.isInClientMode
		self.map = map.id
		self.position = position
	}
	
	func update(from other: Issue) {
		assert(id == other.id)
		
		other.downloadFile(previous: self)
		
		func update<T>(_ keyPath: ReferenceWritableKeyPath<Issue, T>) {
			self[keyPath: keyPath] = other[keyPath: keyPath]
		}
		
		// this is bad to maintain but super handy in every other way
		update(\.meta)
		update(\.number)
		update(\.isMarked)
		update(\.wasAddedWithClient)
		update(\.imageFilename)
		update(\.description)
		update(\.craftsman)
		update(\.map)
		update(\.status)
		update(\.position)
	}
	
	struct Position: Codable {
		var point: Point
		var zoomScale: Double
		
		init(at point: Point, zoomScale: Double) {
			self.point = point
			self.zoomScale = zoomScale
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

extension Issue: FileContainer {
	static let pathPrefix = "issue"
	static let downloadRequestPath = \FileDownloadRequest.issue
	var filename: String? { return imageFilename }
}

extension Issue {
	func accessCraftsman() -> Craftsman? {
		return craftsman.flatMap { Client.shared.storage.craftsmen[$0] }
	}
	
	func accessMap() -> Map {
		return Client.shared.storage.maps[map]!
	}
	
	func accessBuilding() -> Building {
		return accessMap().accessBuilding()
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
	func change(transform: (Issue) throws -> Void) rethrows {
		assert(!isRegistered)
		
		let oldFilename = filename
		try transform(self)
		Client.shared.issueChanged(self, hasChangedFilename: filename != oldFilename)
		
		Client.shared.saveShared()
	}
	
	func mark() {
		isMarked.toggle()
		Client.shared.performed(.mark, on: self)
		
		Client.shared.saveShared()
	}
	
	func review() {
		assert(isRegistered)
		assert(!isReviewed)
		
		status.review = .init(at: Date(), by: Client.shared.user!.fullName)
		Client.shared.performed(.review, on: self)
		
		Client.shared.saveShared()
	}
	
	func revertReview() {
		assert(isReviewed)
		
		status.review = nil
		Client.shared.performed(.revert, on: self)
		
		Client.shared.saveShared()
	}
	
	func revertResponse() {
		assert(hasResponse)
		assert(!isReviewed)
		
		status.response = nil
		Client.shared.performed(.revert, on: self)
		
		Client.shared.saveShared()
	}
}
