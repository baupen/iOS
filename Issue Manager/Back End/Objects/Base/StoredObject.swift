// Created by Julian Dunskus

import Foundation
import GRDB

protocol StoredObject: AnyStoredObject {
	typealias ID = ObjectID<Self>
	typealias Meta = ObjectMeta<Self>
	
	static var apiType: String { get }
	static var apiPath: String { get }
	var apiPath: String { get }
	
	var meta: Meta { get }
	var id: ID { get }
	var isDeleted: Bool { get }
	
	static func onChange(from previous: Self?, to new: Self?)
}

extension StoredObject {
	static var apiPath: String { "/api/\(apiType)" }
	var apiPath: String {
		"\(Self.apiPath)/\(id.rawValue.uuidString.lowercased())"
	}
	
	var id: ID { meta.id }
	
	var rawMeta: AnyObjectMeta { meta }
	var rawID: UUID { id.rawValue }
	var isDeleted: Bool { meta.isDeleted }
	
	static func onChange(from previous: Self?, to new: Self?) {}
}

extension DerivableRequest where RowDecoder: StoredObject {
	var withoutDeleted: Self {
		filter(!RowDecoder.Meta.Columns.isDeleted)
	}
}

protocol AnyStoredObject: DBRecord {
	var rawID: UUID { get }
}
