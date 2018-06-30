// Created by Julian Dunskus

import Foundation

struct Building: FileContainer {
	var meta: ObjectMeta
	var name: String
	var address: Address
	var imageFilename: String?
	var maps: [UUID]
	var craftsmen: [UUID]
	
	static let pathPrefix = "building"
	static let downloadRequestPath = \FileDownloadRequest.building
	var filename: String? { return imageFilename }
	
	func childMaps() -> [Map] {
		return maps.compactMap { Client.shared.storage.maps[$0] }
	}
	
	func allIssues() -> [Issue] {
		return childMaps().flatMap { $0.allIssues() }
	}
	
	struct Address: Codable {
		/// first two address lines (multiline)
		var streetAddress: String?
		var postalCode: Int?
		var locality: String?
		var country: String?
	}
}
