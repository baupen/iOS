// Created by Julian Dunskus

import Foundation
import Promise

/**
A request that can be stored for later execution and released whenever the connection comes back later.

Can't formally require `Request` because that's a PAT and thus can't be stored in an array…
*/
protocol BacklogStorable: Codable {
	static var storageID: String { get }
	
	var method: String { get }
	
	/// You can use this without breaking stuff, but i'd rather you use `Client.shared.send`.
	func send() -> Future<Void>
}

extension BacklogStorable where Self: Request {
	func send() -> Future<Void> {
		return Client.shared.send(self).ignoringResult()
	}
}

let storableTypes: [BacklogStorable.Type] = [
	IssueUpdateRequest.self,
	IssueDeletionRequest.self,
	IssueActionRequest.self,
]

let typesByID = Dictionary(uniqueKeysWithValues: storableTypes.map { ($0.storageID, $0) })

struct Backlog: Codable {
	private var storage: [BacklogStorable] = []
	
	var first: BacklogStorable? {
		return storage.first
	}
	
	init() {}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let raw = try container.decode([StorageHelper].self, forKey: .storage)
		storage = raw.map { $0.request }
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		let raw = storage.map(StorageHelper.init)
		try container.encode(raw, forKey: .storage)
	}
	
	mutating func appendIfPossible<R: Request>(_ request: R) {
		if let storable = request as? BacklogStorable {
			append(storable)
		}
	}
	
	mutating func append(_ request: BacklogStorable) {
		print("\(request.method): storing in backlog")
		storage.append(request)
	}
	
	mutating func removeFirst() {
		storage.removeFirst()
	}
	
	enum CodingKeys: CodingKey {
		case storage
	}
}

fileprivate struct StorageHelper: Codable {
	var request: BacklogStorable
	
	init(containing storable: BacklogStorable) {
		self.request = storable
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let id = try container.decode(String.self, forKey: ._storageID)
		guard let type = typesByID[id] else {
			throw DecodingError.dataCorruptedError(forKey: ._storageID, in: container, debugDescription: "no type found for id \(id)")
		}
		request = try type.init(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(type(of: request).storageID, forKey: ._storageID)
		try request.encode(to: encoder)
	}
	
	enum CodingKeys: CodingKey {
		case _storageID
	}
}
