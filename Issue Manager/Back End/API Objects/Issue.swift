// Created by Julian Dunskus

import Foundation

struct Issue: FileContainer {
	var meta = ObjectMeta()
	var number: Int?
	var isMarked = false
	var wasAddedWithClient: Bool // "abnahmemodus"
	var imageFilename: String?
	var description: String?
	var craftsman: UUID?
	var map: UUID // only really used before registration
	var status: Status = Status()
	var position: Position?
	
	static let pathPrefix = "issue"
	static let downloadRequestPath = \FileDownloadRequest.issue
	var filename: String? { return imageFilename }
	
	init(at position: Position? = nil, in map: Map, wasAddedWithClient: Bool) {
		self.wasAddedWithClient = wasAddedWithClient
		self.map = map.id
		self.position = position
	}
	
	struct Position: Codable {
		var x: Double
		var y: Double
		var zoomScale: Double
	}
	
	struct Status: Codable {
		/// registration in issue collection
		var registration: Event?
		/// response from craftsman
		var response: Event?
		/// review by supervisor
		var review: Event?
		
		struct Event: Codable {
			var time: Date
			/// the name whoever caused the event chose
			var author: String
		}
	}
}
