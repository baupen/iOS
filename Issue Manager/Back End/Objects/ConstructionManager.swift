// Created by Julian Dunskus

import Foundation
import GRDB

struct ConstructionManager: Codable {
	var meta: Meta
	var authenticationToken: String?
	var givenName: String?
	var familyName: String?
	
	var fullName: String {
		[givenName, familyName]
			.compactMap { $0 }
			.joined(separator: " ")
	}
}

extension ConstructionManager: DBRecord {
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		
		container[Columns.authenticationToken] = authenticationToken
		container[Columns.givenName] = givenName
		container[Columns.familyName] = familyName
	}
	
	init(row: Row) {
		meta = .init(row: row)
		
		authenticationToken = row[Columns.authenticationToken]
		givenName = row[Columns.givenName]
		familyName = row[Columns.familyName]
	}
	
	enum Columns: String, ColumnExpression {
		case authenticationToken
		case givenName
		case familyName
	}
}

extension ConstructionManager: StoredObject {
	typealias Model = APIConstructionManager
	static let apiType = "construction_managers"
}
