// Created by Julian Dunskus

import Foundation

struct Map: FileContainer {
	var meta: ObjectMeta
	var children: [UUID]
	var issues: [UUID]
	var filename: String?
	var name: String
	
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
	
	func childMaps() -> [Map] {
		return children.compactMap { Client.shared.storage.maps[$0] }
	}
	
	func recursiveChildren() -> [Map] {
		let children = childMaps()
		return children + children.flatMap { $0.childMaps() }
	}
	
	func allIssues() -> [Issue] {
		return recursiveChildren()
			.lazy
			.flatMap { $0.issues }
			.compactMap { Client.shared.storage.issues[$0] }
	}
}
