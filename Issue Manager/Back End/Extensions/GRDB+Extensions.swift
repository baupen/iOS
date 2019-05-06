// Created by Julian Dunskus

import Foundation
import GRDB

extension QueryInterfaceRequest where T == Issue {
	var consideringClientMode: QueryInterfaceRequest<Issue> {
		return defaults.isInClientMode ? filter(literal: "\(Issue.Columns.wasAddedWithClient)") : self
	}
	
	var openIssues: QueryInterfaceRequest<Issue> {
		return filter(literal: "\(Issue.Columns.review) IS NULL")
	}
	
	var issuesWithResponse: QueryInterfaceRequest<Issue> {
		return filter(literal: "\(Issue.Columns.response) IS NOT NULL")
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
	
	mutating func encodeIfPresent<Column, Value>(
		_ value: Value?,
		forKey key: Column,
		using encoder: JSONEncoder = PersistenceContainer.encoder
	) throws where Column: ColumnExpression, Value: Encodable {
		guard let value = value else { return }
		self[key] = try encoder.encode(value)
	}
}

extension Cursor {
	func count() throws -> Int {
		return try reduce(into: 0) { count, _ in count += 1 }
	}
	
	func count(where condition: (Element) -> Bool) throws -> Int {
		return try reduce(into: 0) { count, element in count += condition(element) ? 1 : 0 }
	}
}
