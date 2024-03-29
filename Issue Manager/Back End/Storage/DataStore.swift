// Created by Julian Dunskus

import UIKit
import GRDB
import HandyOperators

final class DatabaseDataStore: Sendable {
	private static let databaseURL = documentsURL.appendingPathComponent("db/main.sqlite")
	
	static func databaseFileExists() -> Bool {
		FileManager.default.fileExists(atPath: databaseURL.path)
	}
	
	static func wipeData() {
		try? FileManager.default.removeItem(at: databaseURL)
	}
	
	let accessor: any DatabaseWriter
	
	/// Starts up a database in the default location.
	static func fromFile() throws -> Self {
		try FileManager.default.createDirectory(
			at: Self.databaseURL.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		
		let config = Configuration() <- {
			$0.label = "main database"
			#if DEBUG
			// uncomment when needed:
			func debugRepresentation(of string: String, maxLength: Int = 1000) -> String {
				if string.count < maxLength {
					string
				} else {
					"\(string.prefix(maxLength))… <\(string.count - maxLength)/\(string.count) more>"
				}
			}
			//$0.trace = { print("--- executing SQL:", debugRepresentation(of: $0)) }
			#endif
		}
		let pool = try DatabasePool(path: Self.databaseURL.absoluteString, configuration: config)
		return try .init(accessor: pool)
	}
	
	/// Wraps a fresh in-memory database that is discarded on exit.
	static func temporary() throws -> Self {
		try .init(accessor: try DatabaseQueue())
	}
	
	init(accessor: any DatabaseWriter) throws {
		self.accessor = accessor
		
		let migrator = DatabaseMigrator() <- { migrator in
			registerMigrations(in: &migrator)
			
			#if DEBUG
			//migrator.eraseDatabaseOnSchemaChange = true
			#endif
		}
		
		try migrator.migrate(accessor)
	}
	
	private func registerMigrations(in migrator: inout DatabaseMigrator) {
		/// initial setup
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
				$0.column("managers", .blob).notNull()
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
				$0.column("didDelete", .boolean).notNull()
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
		}
		
		/// removal of non-null constraints on construction manager name (happens for registering managers)
		migrator.registerMigration("v2") { db in
			// can't just alter constraints; have to migrate explicitly
			try db.rename(table: "ConstructionManager", to: "_ConstructionManager")
			try db.create(table: "ConstructionManager") {
				$0.primaryKey(["id"])
				// meta
				$0.column("id", .text).notNull()
				$0.column("lastChangeTime", .datetime).notNull()
				$0.column("isDeleted", .boolean).notNull()
				// contents
				$0.column("authenticationToken", .text)
				$0.column("givenName", .text)
				$0.column("familyName", .text)
			}
			try db.execute(sql: "INSERT INTO ConstructionManager SELECT * FROM _ConstructionManager")
			try db.drop(table: "_ConstructionManager")
		}
	}
}

private let documentsURL = try! FileManager.default.url(
	for: .documentDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)

infix operator <-: WithPrecedence // resolve conflict between GRDB and HandyOperators
