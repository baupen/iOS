// Created by Julian Dunskus

import Foundation
import GRDB

extension QueryInterfaceRequest where T == Issue {
	var consideringClientMode: QueryInterfaceRequest<Issue> {
		return defaults.isInClientMode ? filter(Issue.Columns.wasAddedWithClient == true) : self
	}
}

extension Row {
	private static let decoder = JSONDecoder()
	
	func decodeValue<Column, Value>(
		_: Value.Type = Value.self,
		forKey key: Column,
		using decoder: JSONDecoder = Row.decoder
		) throws -> Value where Column: ColumnExpression, Value: Decodable {
		return try decoder.decode(from: self[key])
	}
	
	func decodeValueIfPresent<Column, Value>(
		_: Value.Type = Value.self,
		forKey key: Column,
		using decoder: JSONDecoder = Row.decoder
		) throws -> Value? where Column: ColumnExpression, Value: Decodable {
		return try self[key].map(decoder.decode)
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
}
