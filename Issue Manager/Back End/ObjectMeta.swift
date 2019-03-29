// Created by Julian Dunskus

import Foundation

struct ID<Object>: Codable, Hashable, CustomStringConvertible {
	var rawValue: UUID
	
	var description: String {
		return rawValue.description
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
	
	var stringValue: String {
		return rawValue.uuidString
	}
	
	init() {
		self.rawValue = UUID()
	}
	
	init(_ rawValue: UUID) {
		self.rawValue = rawValue
	}
	
	init(from decoder: Decoder) throws {
		rawValue = try UUID(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try rawValue.encode(to: encoder)
	}
}

protocol AnyAPIObject: Codable {
	var rawMeta: AnyObjectMeta { get }
	var rawID: UUID { get }
}

protocol APIObject: AnyAPIObject {
	var meta: ObjectMeta<Self> { get }
	var id: ID<Self> { get }
}

extension APIObject {
	var id: ID<Self> { return meta.id }
	
	var rawMeta: AnyObjectMeta { return meta }
	var rawID: UUID { return id.rawValue }
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
