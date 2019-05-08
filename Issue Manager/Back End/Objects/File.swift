// Created by Julian Dunskus

import Foundation

struct File: Hashable {
	let id: ID<File>
	var filename: String
}

extension File {
	init(filename: String) {
		self.id = .init()
		self.filename = filename
	}
}

extension File: Codable {}
