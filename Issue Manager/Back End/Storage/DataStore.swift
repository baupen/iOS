// Created by Julian Dunskus

import UIKit
import GRDB

final class DatabaseDataStore {
	var dbPool: DatabasePool
	
	init() throws {
		let databaseURL = documentsURL.appendingPathComponent("db/main.sqlite")
		try FileManager.default.createDirectory(
			at: databaseURL.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		
		let config = Configuration() <- {
			$0.label = "main database"
			#if DEBUG
			// uncomment when needed:
			func debugRepresentation(of string: String, maxLength: Int = 500) -> String {
				if string.count < maxLength {
					return string
				} else {
					return "\(string.prefix(maxLength))… <\(string.count - maxLength)/\(string.count) more>"
				}
			}
			//$0.trace = { print("--- executing SQL:", debugRepresentation(of: $0)) }
			#endif
		}
		dbPool = try .init(path: databaseURL.absoluteString, configuration: config)
		dbPool.setupMemoryManagement(in: UIApplication.shared)
		
		let migrator = DatabaseMigrator() <- { migrator in
			registerMigrations(in: &migrator)
			
			#if DEBUG
			migrator.eraseDatabaseOnSchemaChange = true
			#endif
		}
		
		try migrator.migrate(dbPool)
	}
	
	private func registerMigrations(in migrator: inout DatabaseMigrator) {
		migrator.registerMigration("v1") { db in
			try db.create(table: "ConstructionSite") {
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
			
			try db.create(table: "Map") {
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
					.references("ConstructionSite", onDelete: .cascade, onUpdate: .cascade)
					.indexed()
				$0.column("parentID", .text)
					.references("Map", onDelete: .cascade, onUpdate: .cascade, deferred: true)
					.indexed()
			}
			
			try db.create(table: "Issue") {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .text).notNull()
				// contents
				$0.column("number", .integer)
				$0.column("wasAddedWithClient", .boolean).notNull()
				$0.column("position", .blob)
				$0.column("details", .blob).notNull()
				$0.column("status.registration", .blob)
				$0.column("status.response", .blob)
				$0.column("status.review", .blob)
				// relations
				$0.column("mapID", .text).notNull()
					.references("Map", onDelete: .cascade, onUpdate: .cascade)
					.indexed()
			}
			
			try db.create(table: "Craftsman") {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .text).notNull()
				// contents
				$0.column("name", .text).notNull()
				$0.column("trade", .text).notNull()
				// relations
				$0.column("constructionSiteID", .text).notNull()
					.references("ConstructionSite", onDelete: .cascade, onUpdate: .cascade)
					.indexed()
			}
		}
	}
}

private let documentsURL = try! FileManager.default.url(
	for: .documentDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)
