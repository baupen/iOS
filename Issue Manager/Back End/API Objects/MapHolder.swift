// Created by Julian Dunskus

import Foundation

protocol MapHolder: APIObject {
	var name: String { get }
	var children: [UUID] { get }
	
	func childMaps() -> [Map]
	func recursiveChildren() -> [Map]
	
	func recursiveIssues() -> AnyCollection<Issue>
}

extension MapHolder {
	func childMaps() -> [Map] {
		return children.compactMap { Client.shared.storage.maps[$0] }
	}
	
	func recursiveIssues() -> AnyCollection<Issue> {
		let recursiveIssues = recursiveChildren()
			.lazy
			.flatMap { $0.issues }
			.compactMap { Client.shared.storage.issues[$0] }
		
		if Client.shared.isInClientMode {
			return AnyCollection(recursiveIssues.filter { $0.wasAddedWithClient })
		} else {
			return AnyCollection(recursiveIssues)
		}
	}
}
