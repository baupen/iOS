// Created by Julian Dunskus

import Foundation
import GRDB

struct File: Hashable {
	let id: ID<File>
	var filename: String
}

extension File {
	init(filename: String) {
		self.id = .init()
		self.filename = filename
	}
}

extension File: Codable {}

extension File {
	init(row: Row, path: ColumnExpression) {
		id = row[path • Columns.id]
		filename = row[path • Columns.filename]
	}
	
	func encode(to container: inout PersistenceContainer, path: ColumnExpression) {
		container[path • Columns.id] = id
		container[path • Columns.filename] = filename
	}
	
	enum Columns: String, ColumnExpression {
		case id
		case filename
	}
}

precedencegroup ConcatenationPrecedence {
	associativity: left
}

infix operator • : ConcatenationPrecedence

func • (lhs: ColumnExpression, rhs: ColumnExpression) -> Column {
	return Column("\(lhs.name).\(rhs.name)")
}
