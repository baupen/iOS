// Created by Julian Dunskus

import Foundation
import GRDB

protocol MapHolder: AnyStoredObject {
	var name: String { get }
	var children: QueryInterfaceRequest<Map> { get }
	
	func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest, R.RowDecoder == Map
	var recursiveIssues: QueryInterfaceRequest<Issue> { get }
	func issues(recursively: Bool) -> QueryInterfaceRequest<Issue>
}

extension MapHolder {
	var recursiveIssues: QueryInterfaceRequest<Issue> {
		return Issue
			.joining(required: Issue.map.recursiveChildren(of: self))
			.consideringClientMode
	}
}

extension DerivableRequest where RowDecoder == Map {
	func recursiveChildren(of holder: MapHolder) -> Self {
		return holder.recursiveChildren(in: self)
	}
}

extension ConstructionSite: MapHolder {
	var children: QueryInterfaceRequest<Map> { return maps.filter(Map.Columns.parentID == nil) }
	
	func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest, R.RowDecoder == Map {
		return request.filter(Map.Columns.constructionSiteID == rawID)
	}
	
	func issues(recursively: Bool) -> QueryInterfaceRequest<Issue> {
		precondition(recursively, "construction sites only have recursive issues")
		return recursiveIssues
	}
}

extension Map: MapHolder {
	func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest, R.RowDecoder == Map {
		// recursive common table expression, in case you want to google that
		return request.filter(
			literal: """
			\(sql: Map.databaseTableName).id IN (
				WITH rec_maps AS (
					SELECT \(rawID) AS id
					UNION ALL
					SELECT child.id
						FROM \(sql: Map.databaseTableName) child
						JOIN rec_maps parent ON child.parentID = parent.id
				)
				SELECT id FROM rec_maps
			)
			"""
		)
	}
	
	func issues(recursively: Bool) -> QueryInterfaceRequest<Issue> {
		return recursively ? recursiveIssues : issues
	}
}
