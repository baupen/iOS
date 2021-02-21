// Created by Julian Dunskus

import UIKit
import GRDB

final class DatabaseDataStore {
	private static let databaseURL = documentsURL.appendingPathComponent("db/main.sqlite")
	
	static func wipeData() {
		try? FileManager.default.removeItem(at: databaseURL)
	}
	
	var dbPool: DatabasePool
	
	init() throws {
		try FileManager.default.createDirectory(
			at: Self.databaseURL.deletingLastPathComponent(),
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
		dbPool = try .init(path: Self.databaseURL.absoluteString, configuration: config)
		
		let migrator = DatabaseMigrator() <- { migrator in
			registerMigrations(in: &migrator)
			
			#if DEBUG
			//migrator.eraseDatabaseOnSchemaChange = true
			#endif
		}
		
		try migrator.migrate(dbPool)
	}
	
	private func registerMigrations(in migrator: inout DatabaseMigrator) {
		migrator.registerMigration("v1") { db in
			try db.create(table: "ConstructionManager") {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .datetime).notNull()
				$0.column("isDeleted", .boolean).notNull()
				// contents
				$0.column("authenticationToken", .text)
				$0.column("givenName", .text).notNull()
				$0.column("familyName", .text).notNull()
			}
			
			try db.create(table: "ConstructionSite") {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .datetime).notNull()
				$0.column("isDeleted", .boolean).notNull()
				// contents
				$0.column("name", .text).notNull()
				$0.column("creationTime", .datetime).notNull()
				$0.column("image", .text)
			}
			
			try db.create(table: "Map") {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .datetime).notNull()
				$0.column("isDeleted", .boolean).notNull()
				$0.column("constructionSiteID", .text).notNull()
					.references("ConstructionSite", onDelete: .cascade, onUpdate: .cascade)
					.indexed()
				// contents
				$0.column("name", .text).notNull()
				$0.column("file", .text)
				$0.column("parentID", .text)
					.references("Map", onDelete: .cascade, onUpdate: .cascade, deferred: true)
					.indexed()
			}
			
			try db.create(table: "Issue") {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .datetime).notNull()
				$0.column("isDeleted", .boolean).notNull()
				$0.column("constructionSiteID", .text).notNull()
					.references("ConstructionSite", onDelete: .cascade, onUpdate: .cascade)
					.indexed()
				$0.column("mapID", .text).notNull()
					.references("Map", onDelete: .cascade, onUpdate: .cascade)
					.indexed()
				// contents
				$0.column("number", .integer)
				$0.column("wasAddedWithClient", .boolean).notNull()
				$0.column("deadline", .date)
				
				$0.column("position", .blob)
				$0.column("isMarked", .boolean).notNull()
				$0.column("description", .text)
				$0.column("craftsmanID", .text)
					.references("Craftsman")
				
				$0.column("image", .text)
				
				$0.column("wasUploaded", .boolean).notNull()
				$0.column("didChangeImage", .boolean).notNull()
				$0.column("patchIfChanged", .blob)
				
				// status
				$0.column("createdAt", .datetime)
				$0.column("createdBy", .text)
					.references("ConstructionManager")
				$0.column("registeredAt", .datetime)
				$0.column("registeredBy", .text)
					.references("ConstructionManager")
				$0.column("resolvedAt", .datetime)
				$0.column("resolvedBy", .text)
					.references("Craftsman")
				$0.column("closedAt", .datetime)
				$0.column("closedBy", .text)
					.references("ConstructionManager")
			}
			
			try db.create(table: "Craftsman") {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .datetime).notNull()
				$0.column("isDeleted", .boolean).notNull()
				// contents
				$0.column("contactName", .text).notNull()
				$0.column("company", .text).notNull()
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
