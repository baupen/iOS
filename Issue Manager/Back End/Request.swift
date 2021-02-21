// Created by Julian Dunskus

import Foundation

/// Conform to one of the more specific protocols rather than this.
protocol Request {
	associatedtype Response
	
	/// The http method the request uses.
	static var httpMethod: String { get }
	
	var path: String { get }
	/// If non-nil, the client uses this as the base URL rather than its default.
	var baseURLOverride: URL? { get }
	
	@ArrayBuilder<(String, Any)>
	func collectURLQueryItems() -> [(String, Any)]
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Response
}

extension Request {
	static var httpMethod: String { "POST" }
	
	var baseURLOverride: URL? { nil }
	
	func collectURLQueryItems() -> [(String, Any)] { [] }
}

/// a request that has no body
protocol GetRequest: Request {}

extension GetRequest {
	static var httpMethod: String { "GET" }
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {}
}

/// a request that is encoded as simple JSON
protocol JSONEncodingRequest: Request {
	associatedtype Body: Encodable
	
	var body: Body { get }
}

extension JSONEncodingRequest where Body == Self, Self: Encodable {
	var body: Self { self }
}

extension JSONEncodingRequest {
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {
		request.httpBody = try encoder.encode(body)
	}
}

/// a request that is encoded as a multipart form
protocol MultipartEncodingRequest: Request, Encodable {
	var fileURL: URL? { get }
}

extension MultipartEncodingRequest {
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {
		let encoded = try encoder.encode(self)
		let parts = [MultipartPart(name: "message", content: .json(encoded))]
			+ (fileURL.map { [MultipartPart(name: "image", content: .jpeg(at: $0))] } ?? [])
		try encodeMultipartRequest(containing: parts, into: &request)
	}
}

/// a request that expects a JSON-decodable response
protocol JSONDecodingRequest: Request where Response: Decodable {}

extension JSONDecodingRequest {
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Response {
		try decoder.decode(from: data)
	}
}

/// a request that expects a binary data response
protocol DataDecodingRequest: Request where Response == Data {}

extension DataDecodingRequest {
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Data {
		data
	}
}

typealias JSONJSONRequest = JSONEncodingRequest & JSONDecodingRequest
typealias JSONDataRequest = JSONEncodingRequest & DataDecodingRequest
typealias MultipartJSONRequest = MultipartEncodingRequest & JSONDecodingRequest
