// Created by Julian Dunskus

import Foundation
import GRDB

protocol StoredObject: AnyStoredObject {
	typealias ID = ObjectID<Self>
	typealias Meta = ObjectMeta<Self>
	
	associatedtype Model: APIModel where Model.Object == Self
	
	static var apiType: String { get }
	static var apiPath: String { get }
	var apiPath: String { get }
	
	var meta: Meta { get }
	var id: ID { get }
	var isDeleted: Bool { get }
}

extension StoredObject {
	static var apiPath: String { "/api/\(apiType)" }
	var apiPath: String { id.apiPath }
	
	var id: ID { meta.id }
	
	var rawMeta: AnyObjectMeta { meta }
	var rawID: String { id.rawValue }
	var isDeleted: Bool { meta.isDeleted }
}

extension DerivableRequest where RowDecoder: StoredObject {
	var withoutDeleted: Self {
		filter(!RowDecoder.Meta.Columns.isDeleted)
	}
}

protocol AnyStoredObject: DBRecord {
	var rawID: String { get }
}
