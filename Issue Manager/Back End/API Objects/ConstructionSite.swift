// Created by Julian Dunskus

import Foundation

struct ConstructionSite {
	let meta: ObjectMeta<ConstructionSite>
	let name: String
	let address: Address
	let image: File?
	let maps: [ID<Map>]
	let craftsmen: [ID<Craftsman>]
	
	struct Address: Codable {
		/// first two address lines (multiline)
		var streetAddress: String?
		var postalCode: Int?
		var locality: String?
		var country: String?
	}
}

extension ConstructionSite: APIObject {}

extension ConstructionSite: FileContainer {
	static let pathPrefix = "constructionSite"
	static let downloadRequestPath = \FileDownloadRequest.constructionSite
	var file: File? { return image }
}

extension ConstructionSite: MapHolder {
	var children: [ID<Map>] { return maps }
	
	func recursiveChildren() -> [Map] {
		return childMaps().flatMap { $0.recursiveChildren() }
	}
}

extension ConstructionSite {
	func allCraftsmen() -> [Craftsman] {
		return craftsmen.compactMap(Repository.shared.craftsman)
	}
	
	func allTrades() -> Set<String> {
		return Set(allCraftsmen().map { $0.trade })
	}
}
