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
			let int = Int(raw.dropFirst(), radix: 16)
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
