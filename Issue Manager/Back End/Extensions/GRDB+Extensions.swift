// Created by Julian Dunskus

import Foundation
import GRDB

// need to explicitly list inherited protocols for conditional conformance
typealias DBRecord = PersistableRecord & FetchableRecord & TableRecord & EncodableRecord & MutablePersistableRecord

extension Row {
	private static let decoder = JSONDecoder()
	
	func decodeValue<Value>(
		_: Value.Type = Value.self,
		forKey key: some ColumnExpression,
		using decoder: JSONDecoder = Row.decoder
	) throws -> Value where Value: Decodable {
		try decoder.decode(from: self[key])
	}
	
	func decodeValueIfPresent<Value>(
		_: Value.Type = Value.self,
		forKey key: some ColumnExpression,
		using decoder: JSONDecoder = Row.decoder
	) throws -> Value? where Value: Decodable {
		try (self[key] as Data?).map(decoder.decode)
	}
}

extension PersistenceContainer {
	private static let encoder = JSONEncoder()
	
	mutating func encode<Column, Value>(
		_ value: Value,
		forKey key: Column,
		using encoder: JSONEncoder = PersistenceContainer.encoder
	) throws where Column: ColumnExpression, Value: Encodable {
		self[key] = try encoder.encode(value)
	}
	
	mutating func encode<Column, Value>(
		_ value: Value?,
		forKey key: Column,
		using encoder: JSONEncoder = PersistenceContainer.encoder
	) throws where Column: ColumnExpression, Value: Encodable {
		self[key] = try value.map(encoder.encode)
	}
}
