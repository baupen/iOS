// Created by Julian Dunskus

import Foundation
import GRDB

protocol AnyFile {
	var urlPath: String { get }
}

struct File<Container>: AnyFile, Hashable where Container: FileContainer {
	let urlPath: String
}

extension File: DatabaseValueConvertible {
	static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
		String.fromDatabaseValue(dbValue).map(Self.init)
	}
	
	var databaseValue: DatabaseValue {
		urlPath.databaseValue
	}
}

extension File: Codable {
	init(from decoder: Decoder) throws {
		urlPath = try String(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try urlPath.encode(to: encoder)
	}
}
