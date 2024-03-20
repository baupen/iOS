// Created by Julian Dunskus

import Foundation
import GRDB

protocol StoredObject: DBRecord, Sendable {
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
	typealias Query = QueryInterfaceRequest<Self>
	
	static var apiPath: String { "/api/\(apiType)" }
	var apiPath: String { id.apiPath }
	
	var id: ID { meta.id }
	
	var rawID: String { id.rawValue }
	var isDeleted: Bool { meta.isDeleted }
}

extension DerivableRequest where RowDecoder: StoredObject {
	var withoutDeleted: Self {
		filter(!RowDecoder.Meta.Columns.isDeleted)
	}
}

// pure value types: of course they're sendable
extension QueryInterfaceRequest: @unchecked Sendable {}
extension BelongsToAssociation: @unchecked Sendable {}
extension HasManyAssociation: @unchecked Sendable {}
extension Column: @unchecked Sendable {}
