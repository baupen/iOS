// Created by Julian Dunskus

import Foundation
import GRDB

protocol MapHolder: AnyStoredObject {
	var name: String { get }
	var children: QueryInterfaceRequest<Map> { get }
	
	func recursiveChildren(in db: Database) throws -> [Map]
	
	func recursiveIssues(in db: Database) throws -> AnyCollection<Issue>
}

extension MapHolder {
	func recursiveIssues(in db: Database) throws -> AnyCollection<Issue> {
		let recursiveIssues = try recursiveChildren(in: db)
			.lazy
			.flatMap { try $0.issues.fetchAll(db) }
		
		if defaults.isInClientMode {
			return AnyCollection(recursiveIssues.filter { $0.wasAddedWithClient })
		} else {
			return AnyCollection(recursiveIssues)
		}
	}
}
