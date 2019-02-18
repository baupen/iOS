// Created by Julian Dunskus

import Foundation

extension UserDefaults {
	func decode<T>(_ type: T.Type = T.self, forKey key: String, using decoder: JSONDecoder = JSONDecoder()) throws -> T? where T: Decodable {
		guard let raw = data(forKey: key) else {
			return nil
		}
		return try JSONDecoder().decode(from: raw)
	}
	
	func encode<T>(_ object: T, forKey key: String, using encoder: JSONEncoder = JSONEncoder()) throws where T: Encodable {
		set(try encoder.encode(object), forKey: key)
	}
}
