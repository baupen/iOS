// Created by Julian Dunskus

import Foundation

final class Issue: APIObject {
	// NB: update `update(from:)` when adding/removing stored properties!
	private(set) var meta = ObjectMeta<Issue>()
	private(set) var number: Int?
	private(set) var wasAddedWithClient: Bool // "abnahmemodus"
	private(set) var map: ID<Map> // only really used before registration
	private(set) var status = Status()
	private(set) var position: Position?
	private(set) var details = Details()
	
	var isMarked: Bool { return details.isMarked }
	var image: File? { return details.image }
	var description: String? { return details.description }
	var craftsman: ID<Craftsman>? { return details.craftsman }
	
	init(at position: Position? = nil, in map: Map) {
		self.wasAddedWithClient = defaults.isInClientMode
		self.map = map.id
		self.position = position
	}
	
	static func update(_ instance: inout Issue?, from new: Issue?) {
		switch (instance, new) {
		case (let old?, let new?):
			old.update(from: new)
		case (let old?, nil):
			old.deleteFile()
			instance = nil
		case (nil, let new?):
			new.downloadFile()
			instance = new
		case (nil, nil):
			break
		}
	}
	
	private func update(from other: Issue) {
		other.downloadFile(previous: self)
		
		func update<T>(_ keyPath: ReferenceWritableKeyPath<Issue, T>) {
			self[keyPath: keyPath] = other[keyPath: keyPath]
		}
		
		// this is bad to maintain but super handy in every other way
		assert(id == other.id)
		update(\.meta)
		update(\.number)
		update(\.wasAddedWithClient)
		assert(map == other.map)
		update(\.status)
		update(\.position)
		update(\.details)
		
		Repository.shared.save(self)
	}
	
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
	func change(notifyingServer: Bool = true, transform: (inout Details) throws -> Void) rethrows {
		assert(!isRegistered)
		
		let oldFile = file
		try transform(&details)
		Client.shared.issueChanged(self, hasChangedFile: file != oldFile)
		
		Repository.shared.save(self)
	}
	
	func mark() {
		details.isMarked.toggle()
		Client.shared.performed(.mark, on: self)
		
		Repository.shared.save(self)
	}
	
	func review() {
		assert(isRegistered)
		assert(!isReviewed)
		
		status.review = .init(at: Date(), by: Client.shared.localUser!.user.fullName)
		Client.shared.performed(.review, on: self)
		
		Repository.shared.save(self)
	}
	
	func revertReview() {
		assert(isReviewed)
		
		status.review = nil
		Client.shared.performed(.revert, on: self)
		
		Repository.shared.save(self)
	}
	
	func revertResponse() {
		assert(hasResponse)
		assert(!isReviewed)
		
		status.response = nil
		Client.shared.performed(.revert, on: self)
		
		Repository.shared.save(self)
	}
}
