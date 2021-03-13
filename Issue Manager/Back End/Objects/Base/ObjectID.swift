// Created by Julian Dunskus

import Foundation
import GRDB

struct ObjectID<Object>: Hashable where Object: StoredObject {
	var rawValue: String
	
	var apiPath: String {
		"\(Object.apiPath)/\(apiString)"
	}
	
	var apiString: String {
		rawValue
	}
	
	init() {
		self.rawValue = "\(UUID())"
	}
	
	init(_ rawValue: String) {
		self.rawValue = rawValue
	}
}

extension ObjectID where Object: DBRecord {
	func get(in db: Database) throws -> Object? {
		try Object.fetchOne(db, key: rawValue)
	}
}

extension ObjectID: DatabaseValueConvertible {
	static func fromDatabaseValue(_ dbValue: DatabaseValue) -> ObjectID? {
		String.fromDatabaseValue(dbValue).map(ObjectID.init)
	}
	
	var databaseValue: DatabaseValue {
		rawValue.databaseValue
	}
}

extension ObjectID: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.rawValue = try container.decode(String.self)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}

extension ObjectID: CustomStringConvertible {
	var description: String {
		rawValue.description
	}
}
