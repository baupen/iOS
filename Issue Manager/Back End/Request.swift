// Created by Julian Dunskus

import Foundation

typealias Response = Decodable

/// Conform to one of the more specific protocols rather than this.
protocol Request {
	associatedtype ExpectedResponse
	
	/// The http method the request uses.
	static var httpMethod: String { get }
	/// Independent requests don't depend on results of other requests and, as such, can be executed at any time.
	static var isIndependent: Bool { get }
	
	var method: String { get }
	/// If non-nil, the client uses this as the base URL rather than its default.
	var baseURLOverride: URL? { get }
	
	func applyToClient(_ response: ExpectedResponse)
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws
	func decode(from data: Data, using decoder: JSONDecoder) throws -> ExpectedResponse
}

extension Request {
	static var httpMethod: String { "POST" }
	
	var baseURLOverride: URL? { nil }
	
	func applyToClient(_ response: ExpectedResponse) {}
}

extension Request where Self: BacklogStorable {
	static var isIndependent: Bool { false }
}

/// a request that has no body
protocol GetRequest: Request, Encodable {}

extension GetRequest {
	static var httpMethod: String { "GET" }
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {}
}

/// a request that is encoded as simple JSON
protocol JSONEncodingRequest: Request, Encodable {}

extension JSONEncodingRequest {
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {
		request.httpBody = try encoder.encode(self)
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
protocol JSONDecodingRequest: Request where ExpectedResponse: Response {}

extension JSONDecodingRequest {
	func decode(from data: Data, using decoder: JSONDecoder) throws -> ExpectedResponse {
		try decoder.decode(JSend.Success<ExpectedResponse>.self, from: data).data
	}
}

/// a request that expects a binary data response
protocol DataDecodingRequest: Request where ExpectedResponse == Data {}

extension DataDecodingRequest {
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Data {
		data
	}
}

typealias JSONJSONRequest = JSONEncodingRequest & JSONDecodingRequest
typealias JSONDataRequest = JSONEncodingRequest & DataDecodingRequest
typealias MultipartJSONRequest = MultipartEncodingRequest & JSONDecodingRequest
