// Created by Julian Dunskus

import Foundation

struct File: Codable, Hashable {
	var filename: String
	var id: ID<File>
}
