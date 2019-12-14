// Created by Julian Dunskus

import Foundation

protocol APIModel: Codable {
	associatedtype Object: StoredObject
	
	var meta: ObjectMeta<Object> { get }
	
	var id: ID<Object> { get }
}

extension APIModel {
	var id: ID<Object> { meta.id }
}
