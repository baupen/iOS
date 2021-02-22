// Created by Julian Dunskus

import Foundation
import GRDB

struct ObjectMeta<Object: StoredObject>: AnyObjectMeta, Codable, Equatable {
	var id = Object.ID()
	var lastChangeTime = Date.distantPast // intentionally wrong to not throw off most recent lastChangeTime for sync
	var isDeleted = false
	
	var rawID: UUID { id.rawValue }
}

extension ObjectMeta: DBRecord where Object: DBRecord {
	static var databaseTableName: String { Object.databaseTableName }
	
	enum Columns: String, ColumnExpression {
		case id
		case lastChangeTime
		case isDeleted
	}
}

protocol AnyObjectMeta {
	var rawID: UUID { get }
	var lastChangeTime: Date { get }
	var isDeleted: Bool { get }
}
