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
}
