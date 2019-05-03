// Created by Julian Dunskus

import Foundation
import GRDB

struct ID<Object> {
	var rawValue: UUID
	
	var stringValue: String {
		return rawValue.uuidString
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
		return try Object.fetchOne(db, key: rawValue)
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
		return rawValue.description
	}
}

protocol AnyAPIObject: Codable {
	var rawMeta: AnyObjectMeta { get }
	var rawID: UUID { get }
}

protocol APIObject: AnyAPIObject {
	var meta: ObjectMeta<Self> { get }
	var id: ID<Self> { get }
	
	static func update(_ instance: inout Self?, from new: Self?)
}

extension APIObject {
	var id: ID<Self> { return meta.id }
	
	var rawMeta: AnyObjectMeta { return meta }
	var rawID: UUID { return id.rawValue }
	
	static func update(_ instance: inout Self?, from new: Self?) {
		instance = new
	}
}

protocol AnyObjectMeta {
	var rawID: UUID { get }
	var lastChangeTime: Date { get }
}

struct ObjectMeta<Object: APIObject>: AnyObjectMeta, Codable, Equatable {
	var id = ID<Object>()
	var lastChangeTime = Date()
	
	var rawID: UUID { return id.rawValue }
}
