// Created by Julian Dunskus

import Foundation

extension Sequence {
	func count(where condition: (Element) throws -> Bool) rethrows -> Int {
		return try lazy.filter(condition).count
	}
}

extension Collection {
	var nonEmptyOptional: Self? {
		return isEmpty ? nil : self
	}
}
