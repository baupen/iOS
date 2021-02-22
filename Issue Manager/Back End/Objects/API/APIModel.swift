// Created by Julian Dunskus

import Foundation

protocol APIModel: Decodable {
	associatedtype Object: StoredObject
	associatedtype Context
	
	typealias ID = APIObjectMeta<Self>.ID
	
	func makeObject(meta: Object.Meta, context: Context) -> Object
}

struct APIObject<Model>: Decodable where Model: APIModel {
	var meta: APIObjectMeta<Model>
	var model: Model
	
	init(from decoder: Decoder) throws {
		// flatten
		meta = try .init(from: decoder)
		model = try .init(from: decoder)
	}
	
	func makeObject(context: Model.Context) -> Model.Object {
		model.makeObject(meta: meta.makeObjectMeta(), context: context)
	}
}

extension APIObject where Model.Context == Void {
	func makeObject() -> Model.Object {
		makeObject(context: ())
	}
}

struct APIObjectMeta<Model>: Decodable where Model: APIModel {
	typealias Object = Model.Object
	
	var id: ID
	var lastChangeTime: Date
	var isDeleted: Bool? // construction managers don't get deleted
	
	func makeObjectMeta() -> Object.Meta {
		.init(
			id: id.makeID(),
			lastChangeTime: lastChangeTime,
			isDeleted: isDeleted ?? false
		)
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "@id"
		case lastChangeTime = "lastChangedAt"
		case isDeleted
	}
	
	struct ID: Decodable {
		var rawValue: UUID
		
		init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			let raw = try container.decode(String.self)
			
			let prefix = Object.apiPath + "/"
			guard raw.hasPrefix(prefix) else {
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "encountered invalid IRI string (\"\(raw)\") while decoding an ID starting with \(prefix)"
				)
			}
			let uuidString = String(raw.dropFirst(prefix.count))
			
			self.rawValue = try UUID(uuidString: String(uuidString))
				??? DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "encountered invalid UUID string (\"\(uuidString)\") while decoding an ID"
				)
		}
		
		func makeID() -> Object.ID { .init(self.rawValue) }
	}
}
