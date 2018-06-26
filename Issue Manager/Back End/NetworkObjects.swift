// Created by Julian Dunskus

import Foundation

protocol APIObject: Codable {
	var meta: ObjectMeta { get }
	var id: UUID { get }
}

extension APIObject {
	var id: UUID { return meta.id }
}

struct ObjectMeta: Codable {
	var id = UUID()
	var lastChangeTime = Date()
}

protocol Response: Decodable {}

/**
A basic request doesn't say anything about its response, which makes it handy for `Data` requests and abstraction.

Conform to one of the more specific protocols rather than this.
*/
protocol DataRequest: Encodable {
	associatedtype SendingResult
	
	var method: String { get }
	
	func send() -> Future<SendingResult>
}

/**
A request that expects a JSON-decodable response.

Conform to one of the more specific protocols rather than this.
*/
protocol Request: DataRequest {
	associatedtype ExpectedResponse: Response
}

/// A request that is encoded to JSON and expects a binary data response.
protocol JSONDataRequest: DataRequest {}

/// A request that is sent as simple JSON data and expects a JSON response.
protocol JSONJSONRequest: Request {}

/// A request that is encoded as multipart form data and expects a JSON response.
protocol MultipartJSONRequest: Request {
	var fileURL: URL? { get }
}

extension JSONDataRequest where SendingResult == Data {
	func send() -> Future<Data> {
		return Client.shared.send(self)
	}
}

/// A request that can apply its result to the client
protocol ApplyingRequest: Request {
	func applyToClient(_ response: ExpectedResponse)
}

protocol BacklogStorable: Codable {
	var method: String { get }
	
	func send() -> Future<Void>
}

extension BacklogStorable where Self: ApplyingRequest {
	fileprivate func handle(_ result: Future<ExpectedResponse>) -> Future<Void> {
		return result.map(applyToClient).catch { error in
			if case RequestError.communicationError = error {
				Client.shared.addToBacklog(self)
			}
		}
	}
}

extension JSONJSONRequest where Self: ApplyingRequest & BacklogStorable, SendingResult == Void {
	func send() -> Future<Void> {
		return handle(Client.shared.send(self))
	}
}

extension MultipartJSONRequest where Self: ApplyingRequest & BacklogStorable, SendingResult == Void {
	func send() -> Future<Void> {
		return handle(Client.shared.send(self))
	}
}
