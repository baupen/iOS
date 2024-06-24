// Created by Julian Dunskus

import Foundation
import GRDB

struct ObjectMeta<Object: StoredObject>: Codable, Equatable {
	var id = Object.ID()
	var lastChangeTime = Date.distantPast // intentionally wrong to not throw off most recent lastChangeTime for sync
	var isDeleted = false
	
	var rawID: String { id.rawValue }
}

extension ObjectMeta: DBRecord where Object: DBRecord {
	static var databaseTableName: String { Object.databaseTableName }
	
	enum Columns: String, ColumnExpression {
		case id
		case lastChangeTime
		case isDeleted
	}
}
