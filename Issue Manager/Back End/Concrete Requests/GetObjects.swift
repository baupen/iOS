// Created by Julian Dunskus

import Foundation
import Protoquest

struct GetObjectRequest<Object: StoredObject>: GetJSONRequest, BaupenRequest {
	typealias Response = APIObject<Object.Model>
	
	var path: String
}

extension GetObjectRequest {
	init(for id: Object.ID) {
		path = id.apiPath
	}
}

struct GetObjectsRequest<Object: StoredObject>: GetJSONRequest, BaupenRequest {
	typealias Response = HydraCollection<APIObject<Object.Model>>
	
	var path: String { Object.apiPath }
	
	var constructionSite: ConstructionSite.ID?
	var minLastChangeTime: Date?
	
	var urlParams: [URLParameter] {
		if let constructionSite = constructionSite {
			("constructionSite", constructionSite.apiString)
		}
		
		if let minLastChangeTime = minLastChangeTime {
			("lastChangedAt[after]", Client.dateFormatter.string(from: minLastChangeTime))
		}
	}
}

struct GetPagedObjectsRequest<Model: APIModel>: GetJSONRequest, BaupenRequest {
	typealias Response = PagedHydraCollection<APIObject<Model>>
	
	var path: String { Model.Object.apiPath }
	
	var constructionSite: ConstructionSite.ID?
	var minLastChangeTime: Date
	var page = 1
	var itemsPerPage = 1000
	
	var urlParams: [URLParameter] {
		if let constructionSite = constructionSite {
			("constructionSite", constructionSite.apiString)
		}
		
		("lastChangedAt[after]", Client.dateFormatter.string(from: minLastChangeTime))
		("order[lastChangedAt]", "asc")
		
		("page", page)
		("itemsPerPage", itemsPerPage)
	}
}
