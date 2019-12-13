// Created by Julian Dunskus

import Foundation

extension Sequence {
	func count(where condition: (Element) throws -> Bool) rethrows -> Int {
		try lazy.filter(condition).count
	}
}

extension Collection {
	var nonEmptyOptional: Self? {
		isEmpty ? nil : self
	}
}
