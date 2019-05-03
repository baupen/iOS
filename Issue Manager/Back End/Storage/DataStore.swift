// Created by Julian Dunskus

import UIKit
import Promise
import GRDB

/// saving to disk is done on this queue to avoid blocking
private let savingQueue = DispatchQueue(label: "saving repository")

final class DatabaseDataStore {
	var dbPool: DatabasePool
	
	init() throws {
		let databaseURL = documentsURL.appendingPathComponent("db/main.sqlite")
		try FileManager.default.createDirectory(at: databaseURL.deletingLastPathComponent(), withIntermediateDirectories: true)
		let config = Configuration() <- {
			$0.label = "main database"
			#if DEBUG
			// uncomment when needed:
			//$0.trace = { print("--- executing SQL:", $0) }
			#endif
		}
		dbPool = try .init(path: databaseURL.absoluteString, configuration: config)
		dbPool.setupMemoryManagement(in: UIApplication.shared)
		
		var migrator = DatabaseMigrator()
		migrator.registerMigration("v1") { db in
			try db.create(table: ConstructionSite.databaseTableName) {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .text).notNull()
				// contents
				$0.column("name", .text).notNull()
				$0.column("image", .blob)
				// address
				$0.column("streetAddress", .text)
				$0.column("postalCode", .integer)
				$0.column("locality", .text)
				$0.column("country", .text)
			}
			
			try db.create(table: Map.databaseTableName) {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .text).notNull()
				// contents
				$0.column("sectors", .blob).notNull()
				$0.column("sectorFrame", .blob)
				$0.column("file", .blob)
				$0.column("name", .text).notNull()
				// relations
				$0.column("constructionSiteID", .text).notNull()
					.references(ConstructionSite.databaseTableName)
					.indexed()
				$0.column("parentID", .text)
					.references(Map.databaseTableName, deferred: true)
					.indexed()
			}
			
			try db.create(table: Issue.databaseTableName) {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .text).notNull()
				// contents
				$0.column("number", .integer)
				$0.column("wasAddedWithClient", .boolean).notNull()
				$0.column("position", .blob)
				$0.column("status", .blob).notNull()
				$0.column("details", .blob).notNull()
				// relations
				$0.column("mapID", .text).notNull()
					.references(Map.databaseTableName)
					.indexed()
			}
			
			try db.create(table: Craftsman.databaseTableName) {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .text).notNull()
				// contents
				$0.column("name", .text).notNull()
				$0.column("trade", .text).notNull()
				// relations
				$0.column("constructionSiteID", .text).notNull()
					.references(ConstructionSite.databaseTableName)
					.indexed()
			}
			
		}
		
		#if DEBUG
		migrator.eraseDatabaseOnSchemaChange = true
		#endif
		
		try migrator.migrate(dbPool)
	}
	
	func clear() {
		try! dbPool.write { db in
			try ConstructionSite.deleteAll(db)
			try Map.deleteAll(db)
			try Issue.deleteAll(db)
			try Craftsman.deleteAll(db)
		}
	}
}

// need to explicitly list inherited protocols for conditional conformance
typealias DBRecord = PersistableRecord & FetchableRecord & TableRecord & EncodableRecord & MutablePersistableRecord

extension ObjectMeta: DBRecord where Object: DBRecord {
	static var databaseTableName: String { return Object.databaseTableName }
}

extension ID: DatabaseValueConvertible {
	static func fromDatabaseValue(_ dbValue: DatabaseValue) -> ID? {
		return UUID.fromDatabaseValue(dbValue).map(ID.init)
	}
	
	var databaseValue: DatabaseValue {
		return rawValue.databaseValue
	}
}

let documentsURL = try! FileManager.default.url(
	for: .documentDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)
