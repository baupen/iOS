// Created by Julian Dunskus

import Foundation

extension NSError {
	/// Creates an `NSError` object with the specified parameters. (Because the default initializer is terrible.)
	convenience init(code: Int = 0, localizedDescription: String? = nil, localizedRecoverySuggestion: String? = nil) {
		var userInfo: [String: Any] = [:]
		userInfo[NSLocalizedDescriptionKey] = localizedDescription
		userInfo[NSLocalizedRecoverySuggestionErrorKey] = localizedRecoverySuggestion
		self.init(domain: "com.juliand665.LeagueKit", code: code, userInfo: userInfo)
	}
}

@discardableResult fileprivate func with<T>(_ object: T, do transform: (inout T) throws -> Void) rethrows -> T {
	var copy = object
	try transform(&copy)
	return copy
}

infix operator <-: NilCoalescingPrecedence

@discardableResult public func <- <T>(lhs: T, rhs: (inout T) throws -> Void) rethrows -> T {
	return try with(lhs, do: rhs)
}

infix operator ???: NilCoalescingPrecedence

func ??? <Wrapped>(optional: Wrapped?, error: @autoclosure () -> Error) throws -> Wrapped {
	guard let unwrapped = optional else {
		throw error()
	}
	return unwrapped
}
