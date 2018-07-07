// Created by Julian Dunskus

import Foundation

struct Building: MapHolder, FileContainer {
	var meta: ObjectMeta
	var name: String
	var address: Address
	var imageFilename: String?
	var maps: [UUID]
	var craftsmen: [UUID]
	
	static let pathPrefix = "building"
	static let downloadRequestPath = \FileDownloadRequest.building
	var filename: String? { return imageFilename }
	
	var children: [UUID] { return maps }
	
	func recursiveChildren() -> [Map] {
		return childMaps().flatMap { $0.recursiveChildren() }
	}
	
	struct Address: Codable {
		/// first two address lines (multiline)
		var streetAddress: String?
		var postalCode: Int?
		var locality: String?
		var country: String?
	}
}
