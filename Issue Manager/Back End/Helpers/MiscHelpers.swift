// Created by Julian Dunskus

import Foundation

infix operator <-: NilCoalescingPrecedence

@discardableResult public func <- <T>(object: T, transform: (inout T) throws -> Void) rethrows -> T {
	var copy = object
	try transform(&copy)
	return copy
}

infix operator ???: NilCoalescingPrecedence

func ??? <Wrapped>(optional: Wrapped?, error: @autoclosure () -> Error) throws -> Wrapped {
	guard let unwrapped = optional else {
		throw error()
	}
	return unwrapped
}

extension Error {
	var localizedFailureReason: String {
		return (self as NSError).localizedFailureReason ?? localizedDescription
	}
}

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
