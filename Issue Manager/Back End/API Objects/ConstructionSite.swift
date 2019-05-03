// Created by Julian Dunskus

import Foundation
import GRDB

struct ConstructionSite {
	let meta: ObjectMeta<ConstructionSite>
	let name: String
	let address: Address
	let image: File?
	
	struct Address {
		/// first two address lines (multiline)
		var streetAddress: String?
		var postalCode: Int?
		var locality: String?
		var country: String?
	}
}

extension ConstructionSite.Address: Codable {}

extension ConstructionSite.Address: DBRecord {}

extension ConstructionSite: DBRecord {
	static let craftsmen = hasMany(Craftsman.self)
	var craftsmen: QueryInterfaceRequest<Craftsman> { // FIXME: remove prefix
		return request(for: ConstructionSite.craftsmen)
	}
	
	static let maps = hasMany(Map.self)
	var maps: QueryInterfaceRequest<Map> { // FIXME: remove prefix
		return request(for: ConstructionSite.maps)
	}
	
	func encode(to container: inout PersistenceContainer) {
		meta.encode(to: &container)
		container[Columns.name] = name
		address.encode(to: &container)
		image?.encode(to: &container, path: Columns.image)
	}
	
	init(row: Row) {
		meta = .init(row: row)
		name = row[Columns.name]
		address = .init(row: row)
		image = .init(row: row, path: Columns.image)
	}
	
	enum Columns: String, ColumnExpression {
		case name
		case image
	}
}

extension ConstructionSite: APIObject {}

extension ConstructionSite: FileContainer {
	static let pathPrefix = "constructionSite"
	static let downloadRequestPath = \FileDownloadRequest.constructionSite
	var file: File? { return image }
}

extension ConstructionSite: MapHolder {
	var children: QueryInterfaceRequest<Map> { return maps }
	
	func recursiveChildren(in db: Database) throws -> [Map] {
		return try children.fetchAll(db).flatMap { try $0.recursiveChildren(in: db) }
	}
}

extension ConstructionSite {
	func allTrades() -> Set<String> {
		return Set(Repository.shared.read(craftsmen
			.select(Craftsman.Columns.trade, as: String.self)
			.distinct()
			.fetchAll
		))
	}
}
