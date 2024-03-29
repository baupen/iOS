// Created by Julian Dunskus

import Foundation
import GRDB

protocol MapHolder: StoredObject {
	var name: String { get }
	var children: Map.Query { get }
	var constructionSiteID: ConstructionSite.ID { get }
	var isDeleted: Bool { get }
	
	@MainActor func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest<Map>
	@MainActor var recursiveIssues: Issue.Query { get }
	@MainActor func issues(recursively: Bool) -> Issue.Query
	func freshlyFetched(in repository: Repository) -> Self?
}

extension MapHolder {
	@MainActor
	var recursiveIssues: Issue.Query {
		Issue
			.all()
			.withoutDeleted
			.consideringClientMode
			.joining(required: Issue.map.recursiveChildren(of: self))
	}
}

extension DerivableRequest<Map> {
	@MainActor
	func recursiveChildren(of holder: some MapHolder) -> Self {
		holder.recursiveChildren(in: self)
	}
}

extension ConstructionSite: MapHolder {
	var children: Map.Query { maps.filter(Map.Columns.parentID == nil) }
	
	var constructionSiteID: ID { id }
	
	func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest<Map> {
		request.filter(Map.Columns.constructionSiteID == id)
	}
	
	func issues(recursively: Bool) -> Issue.Query {
		precondition(recursively, "construction sites only have recursive issues")
		return recursiveIssues
	}
	
	func freshlyFetched(in repository: Repository) -> Self? {
		repository.object(id)
	}
}

extension Map: MapHolder {
	func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest<Map> {
		// recursive common table expression, in case you want to google that
		request.filter(
			literal: """
			\(sql: Map.databaseTableName).id IN (
				WITH rec_maps AS (
					SELECT \(rawID) AS id
					UNION
					SELECT child.id
						FROM \(sql: Map.databaseTableName) child
						JOIN rec_maps parent ON child.parentID = parent.id
				)
				SELECT id FROM rec_maps
			)
			"""
		)
	}
	
	func issues(recursively: Bool) -> Issue.Query {
		recursively ? recursiveIssues : issues
	}
	
	func freshlyFetched(in repository: Repository) -> Self? {
		repository.object(id)
	}
}
