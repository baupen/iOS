// Created by Julian Dunskus

import Foundation

struct Map: MapHolder, FileContainer {
	var meta: ObjectMeta
	var children: [UUID]
	var issues: [UUID]
	var filename: String?
	var name: String
	
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
	
	func recursiveChildren() -> [Map] {
		return [self] + childMaps().flatMap { $0.recursiveChildren() }
	}
	
	func allIssues() -> AnyCollection<Issue> {
		return AnyCollection(issues.lazy.compactMap { Client.shared.storage.issues[$0] })
	}
}
