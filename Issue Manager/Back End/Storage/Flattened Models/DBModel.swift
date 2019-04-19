// Created by Julian Dunskus

import Foundation

protocol DBModelable: APIObject {
	associatedtype Model: DBModel where Model.Object == Self
	
	func makeModel() -> Model
	
	init(from model: Model)
}

extension DBModelable {
	func makeModel() -> Model {
		return Model(from: self)
	}
	
	init(from model: Model) {
		self = model.makeObject()
	}
}

protocol DBModel {
	associatedtype Object: DBModelable where Object.Model == Self
	
	var id: UUID { get }
	var lastChangeTime: Date { get }
	
	var meta: ObjectMeta<Object> { get }
	
	func makeObject() -> Object
	
	init(from object: Object)
}

extension DBModel {
	var meta: ObjectMeta<Object> {
		return .init(id: .init(id), lastChangeTime: lastChangeTime)
	}
	
	func makeObject() -> Object {
		return Object(from: self)
	}
	
	init(from object: Object) {
		self = object.makeModel()
	}
}
