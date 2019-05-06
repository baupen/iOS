// Created by Julian Dunskus

import Foundation
import GRDB

protocol MapHolder: AnyStoredObject {
	var name: String { get }
	var children: QueryInterfaceRequest<Map> { get }
	
	var recursiveChildren: QueryInterfaceRequest<Map> { get }
	var recursiveIssues: QueryInterfaceRequest<Issue> { get }
}

extension MapHolder {
	var recursiveIssues: QueryInterfaceRequest<Issue> {
		return recursiveChildren
			.including(required: Map.issues)
			.select([], as: Issue.self)
			.consideringClientMode
	}
}

extension Map: MapHolder {
	var recursiveChildren: QueryInterfaceRequest<Map> {
		// recursive common table expression, in case you want to google that
		return Map.filter(
			sql: """
			\(Map.databaseTableName).id IN (
				WITH rec_maps AS (
					SELECT id
						FROM \(Map.databaseTableName)
						WHERE id = x'\(rawID.hexString)'
					UNION ALL
					SELECT child.id
						FROM \(Map.databaseTableName) child
						JOIN rec_maps parent ON child.parentID = parent.id
				)
				SELECT id FROM rec_maps
			)
			""" // args aren't replaced for whatever reason, so i'm just putting them straight in
		)
	}
}

extension ConstructionSite: MapHolder {
	var children: QueryInterfaceRequest<Map> { return maps }
	
	var recursiveChildren: QueryInterfaceRequest<Map> {
		return Map.filter(Map.Columns.constructionSiteID == rawID)
	}
}

extension UUID {
	public var hexString: String {
		return withUnsafeBytes(of: self) {
			Data(bytes: $0.baseAddress!, count: $0.count).hexEncodedString()
		}
	}
}
