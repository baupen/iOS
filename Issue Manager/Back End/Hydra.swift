// Created by Julian Dunskus

import Foundation

struct HydraCollection<Object>: Decodable where Object: Decodable {
	var members: [Object]
	
	private enum CodingKeys: String, CodingKey {
		case members = "hydra:member"
	}
}

struct PagedHydraCollection<Object>: Decodable where Object: Decodable {
	var members: [Object]
	var totalCount: Int
	var view: View
	
	private enum CodingKeys: String, CodingKey {
		case members = "hydra:member"
		case totalCount = "hydra:totalItems"
		case view = "hydra:view"
	}
	
	struct View: Decodable {
		// even first and last can be nil for empty collections or when full collection is visible
		var firstPage: String?
		var lastPage: String?
		var previousPage: String?
		var nextPage: String?
		
		private enum CodingKeys: String, CodingKey {
			case firstPage = "hydra:first"
			case lastPage = "hydra:last"
			case previousPage = "hydra:previous"
			case nextPage = "hydra:next"
		}
	}
}

struct HydraError: Decodable, Error {
	static let type = "hydra:Error"
	
	var title: String
	var description: String
	
	private enum CodingKeys: String, CodingKey {
		case title = "hydra:title"
		case description = "hydra:description"
	}
}

struct HydraMetadata: Decodable {
	var type: String
	
	private enum CodingKeys: String, CodingKey {
		case type = "@type"
	}
}
