// Created by Julian Dunskus

import Foundation
import GRDB

struct ID<Object> {
	var rawValue: UUID
	
	var stringValue: String {
		rawValue.uuidString
	}
	
	init() {
		self.rawValue = UUID()
	}
	
	init(_ rawValue: UUID) {
		self.rawValue = rawValue
	}
}

extension ID where Object: DBRecord {
	func get(in db: Database) throws -> Object? {
		try Object.fetchOne(db, key: rawValue)
	}
}

extension ID: DatabaseValueConvertible {
	static func fromDatabaseValue(_ dbValue: DatabaseValue) -> ID? {
		UUID.fromDatabaseValue(dbValue).map(ID.init)
	}
	
	var databaseValue: DatabaseValue {
		rawValue.databaseValue
	}
}

extension ID: Codable {
	init(from decoder: Decoder) throws {
		rawValue = try UUID(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try rawValue.encode(to: encoder)
	}
}

extension ID: Hashable {}

extension ID: CustomStringConvertible {
	var description: String {
		rawValue.description
	}
}

protocol AnyStoredObject: Codable {
	var rawMeta: AnyObjectMeta { get }
	var rawID: UUID { get }
}

protocol StoredObject: AnyStoredObject {
	var meta: ObjectMeta<Self> { get }
	var id: ID<Self> { get }
	
	static func onChange(from previous: Self?, to new: Self?)
}

extension StoredObject {
	typealias Meta = ObjectMeta<Self>
	
	var id: ID<Self> { meta.id }
	
	var rawMeta: AnyObjectMeta { meta }
	var rawID: UUID { id.rawValue }
	
	static func onChange(from previous: Self?, to new: Self?) {}
}

protocol AnyObjectMeta {
	var rawID: UUID { get }
	var lastChangeTime: Date { get }
}

struct ObjectMeta<Object: StoredObject>: AnyObjectMeta, Codable, Equatable {
	var id = ID<Object>()
	var lastChangeTime = Date()
	
	var rawID: UUID { id.rawValue }
}

extension ObjectMeta: DBRecord where Object: DBRecord {
	static var databaseTableName: String { Object.databaseTableName }
	
	enum Columns: String, ColumnExpression {
		case id
		case lastChangeTime
	}
}
