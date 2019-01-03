// Created by Julian Dunskus

import Foundation

struct Point: Codable {
	var x: Double
	var y: Double
}

struct Color: Codable {
	var red: UInt8
	var green: UInt8
	var blue: UInt8
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let raw = try container.decode(String.self)
		guard
			raw.count == 7,
			raw.hasPrefix("#"),
			let int = Int(raw.dropFirst(raw.hasPrefix("#") ? 1 : 0), radix: 16)
			else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expecting hex string #RRGGBB, got '\(raw)'") }
		
		red = UInt8(int >> 16 & 0xFF)
		green = UInt8(int >> 8 & 0xFF)
		blue = UInt8(int >> 0 & 0xFF)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		let int = Int(red) << 16 | Int(green) << 8 | Int(blue) << 0
		try container.encode(String(format: "#%06x", int))
	}
}

struct File: Codable, Hashable {
	var filename: String
	var id: ID<File>
}

struct Rectangle: Codable, Hashable {
	static let zero = Rectangle(x: 0, y: 0, width: 0, height: 0)
	static let unit = Rectangle(x: 0, y: 0, width: 1, height: 1)
	
	var x: Double
	var y: Double
	var width: Double
	var height: Double
	
	var origin: Point {
		return Point(x: x, y: y)
	}
	
	enum CodingKeys: String, CodingKey {
		case x = "startX"
		case y = "startY"
		case width, height
	}
}
