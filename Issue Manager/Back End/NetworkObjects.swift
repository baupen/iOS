// Created by Julian Dunskus

import Foundation

struct ID<Object>: Codable, Hashable, CustomStringConvertible {
	var rawValue: UUID
	
	var description: String {
		return rawValue.description
	}
	
	var hashValue: Int {
		return rawValue.hashValue
	}
	
	var stringValue: String {
		return rawValue.uuidString
	}
	
	init() {
		self.rawValue = UUID()
	}
	
	init(_ rawValue: UUID) {
		self.rawValue = rawValue
	}
	
	init(from decoder: Decoder) throws {
		rawValue = try UUID(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try rawValue.encode(to: encoder)
	}
}

protocol AnyAPIObject: Codable {
	var rawMeta: AnyObjectMeta { get }
	var rawID: UUID { get }
}

protocol APIObject: AnyAPIObject {
	var meta: ObjectMeta<Self> { get }
	var id: ID<Self> { get }
}

extension APIObject {
	var id: ID<Self> { return meta.id }
	
	var rawMeta: AnyObjectMeta { return meta }
	var rawID: UUID { return id.rawValue }
}

protocol AnyObjectMeta {
	var rawID: UUID { get }
	var lastChangeTime: Date { get }
}

struct ObjectMeta<Object: APIObject>: AnyObjectMeta, Codable, Equatable {
	var id = ID<Object>()
	var lastChangeTime = Date()
	
	var rawID: UUID { return id.rawValue }
}

typealias Response = Decodable

/// Conform to one of the more specific protocols rather than this.
protocol Request {
	associatedtype ExpectedResponse
	
	/// If non-nil, the client uses this as the base URL rather than its default.
	static var baseURLOverride: URL? { get }
	/// The http method the request uses.
	static var httpMethod: String { get }
	/// Independent requests don't depend on results of other requests and, as such, can be executed at any time.
	static var isIndependent: Bool { get }
	
	var method: String { get }
	var username: String { get }
	
	func applyToClient(_ response: ExpectedResponse)
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws
	func decode(from data: Data, using decoder: JSONDecoder) throws -> ExpectedResponse
}

extension Request {
	static var baseURLOverride: URL? { return nil }
	static var httpMethod: String { return "POST" }
	
	func applyToClient(_ response: ExpectedResponse) {}
	
	var username: String { return Client.shared.localUser!.username }
}

extension Request where Self: BacklogStorable {
	static var isIndependent: Bool { return false }
}

/// a request that has no body
protocol GetRequest: Request, Encodable {}

extension GetRequest {
	static var httpMethod: String { return "GET" }
	
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
		return try decoder.decode(JSend.Success<ExpectedResponse>.self, from: data).data
	}
}

/// a request that expects a binary data response
protocol DataDecodingRequest: Request where ExpectedResponse == Data {}

extension DataDecodingRequest {
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Data {
		return data
	}
}

typealias JSONJSONRequest = JSONEncodingRequest & JSONDecodingRequest
typealias JSONDataRequest = JSONEncodingRequest & DataDecodingRequest
typealias MultipartJSONRequest = MultipartEncodingRequest & JSONDecodingRequest
