// Created by Julian Dunskus

import Foundation

struct File<Container>: Hashable where Container: FileContainer {
	let id: ID<File<Container>>
	var filename: String
}

extension File {
	init(filename: String) {
		self.id = .init()
		self.filename = filename
	}
}

extension File: Codable {}
