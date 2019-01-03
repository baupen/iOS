// Created by Julian Dunskus

import Foundation

final class Map: APIObject {
	let meta: ObjectMeta<Map>
	let children: [ID<Map>]
	let sectors: [Sector]
	let sectorFrame: Rectangle?
	var issues: [ID<Issue>]
	let file: File?
	let name: String
	let constructionSiteID: ID<ConstructionSite>
	
	final class Sector: Codable {
		let name: String
		let color: Color
		let points: [Point]
	}
}

extension Map: FileContainer {
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
}

extension Map: MapHolder {
	func recursiveChildren() -> [Map] {
		return [self] + childMaps().flatMap { $0.recursiveChildren() }
	}
}

extension Map {
	func allIssues() -> [Issue] {
		if defaults.isInClientMode {
			return issues.lazy
				.compactMap { Client.shared.storage.issues[$0] }
				.filter { $0.wasAddedWithClient }
		} else {
			return issues.compactMap { Client.shared.storage.issues[$0] }
		}
	}
	
	func accessSite() -> ConstructionSite {
		return Client.shared.storage.sites[constructionSiteID]!
	}
}
