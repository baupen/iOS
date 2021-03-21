// Created by Julian Dunskus

import Foundation

extension JSONDecoder {
	/// convenient type-inferring version of `decode(_:from:)`
	func decode<T>(from data: Data) throws -> T where T: Decodable {
		try decode(T.self, from: data)
	}
}
