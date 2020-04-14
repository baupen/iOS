// Created by Julian Dunskus

import Foundation

struct Point: Codable {
	var x: Double
	var y: Double
}

struct Rectangle: Codable, Hashable {
	static let zero = Rectangle(x: 0, y: 0, width: 0, height: 0)
	static let unit = Rectangle(x: 0, y: 0, width: 1, height: 1)
	
	var x: Double
	var y: Double
	var width: Double
	var height: Double
	
	var origin: Point {
		Point(x: x, y: y)
	}
	
	private enum CodingKeys: String, CodingKey {
		case x = "startX"
		case y = "startY"
		case width, height
	}
}
