// Created by Julian Dunskus

import Foundation

extension KeyedDecodingContainer {
	/**
	convenient type-inferring version of `decode(_:forKey:)`
	
	throws an error if key missing
	*/
	func decodeValue<T>(forKey key: Key) throws -> T where T: Decodable {
		return try decode(T.self, forKey: key)
	}
	
	/**
	convenient type-inferring version of `decodeIfPresent(_:forKey:)`
	
	returns nil if key missing
	*/
	func decodeValueIfPresent<T>(forKey key: Key) throws -> T? where T: Decodable {
		return try decodeIfPresent(T.self, forKey: key)
	}
	
	/**
	convenient type-inferring version of `tryToDecode(_:forKey:)`
	
	returns nil on error
	*/
	func tryToDecodeValue<T>(forKey key: Key) -> T? where T: Decodable {
		return try? decode(T.self, forKey: key)
	}
	
	/**
	convenient type-inferring version of `decode(_:forKey:)`
	
	returns nil on error
	*/
	func tryToDecode<T>(_ type: T.Type, forKey key: Key) -> T? where T: Decodable {
		return try? decode(T.self, forKey: key)
	}
}

extension JSONDecoder {
	/// convenient type-inferring version of `decode(_:from:)`
	func decode<T>(from data: Data) throws -> T where T: Decodable {
		return try decode(T.self, from: data)
	}
}
