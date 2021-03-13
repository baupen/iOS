// Created by Julian Dunskus

import Foundation

@_functionBuilder
enum ArrayBuilder<Element> {
	static func buildExpression(_ element: Element) -> [Element] { [element] }
	static func buildExpression(_ elements: [Element]) -> [Element] { elements }
	
	static func buildBlock(_ content: [Element]) -> [Element] { content }
	static func buildBlock(_ contents: [Element]...) -> [Element] {
		Array(contents.joined())
	}
	
	static func buildOptional(_ content: [Element]?) -> [Element] { content ?? [] }
	
	static func buildEither(first: [Element]) -> [Element] { first }
	static func buildEither(second: [Element]) -> [Element] { second }
	
	static func buildArray(_ contents: [[Element]]) -> [Element] {
		Array(contents.joined())
	}
}
