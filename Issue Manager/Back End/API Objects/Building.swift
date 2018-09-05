// Created by Julian Dunskus

import Foundation

struct Building: APIObject {
	var meta: ObjectMeta<Building>
	var name: String
	var address: Address
	var imageFilename: String?
	var maps: [ID<Map>]
	var craftsmen: [ID<Craftsman>]
	
	struct Address: Codable {
		/// first two address lines (multiline)
		var streetAddress: String?
		var postalCode: Int?
		var locality: String?
		var country: String?
	}
}

extension Building: FileContainer {
	static let pathPrefix = "building"
	static let downloadRequestPath = \FileDownloadRequest.building
	var filename: String? { return imageFilename }
}

extension Building: MapHolder {
	var children: [ID<Map>] { return maps }
	
	func recursiveChildren() -> [Map] {
		return childMaps().flatMap { $0.recursiveChildren() }
	}
}

extension Building {
	func allCraftsmen() -> [Craftsman] {
		return craftsmen.compactMap { Client.shared.storage.craftsmen[$0] }
	}
	
	func allTrades() -> Set<String> {
		return Set(allCraftsmen().map { $0.trade })
	}
}
