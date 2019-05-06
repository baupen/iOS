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
		image.map { try! container.encode($0, forKey: Columns.image) }
	}
	
	init(row: Row) {
		meta = .init(row: row)
		name = row[Columns.name]
		address = .init(row: row)
		image = try! row.decodeValueIfPresent(forKey: Columns.image)
	}
	
	enum Columns: String, ColumnExpression {
		case name
		case image
	}
}

extension ConstructionSite: StoredObject {}

extension ConstructionSite: FileContainer {
	static let pathPrefix = "constructionSite"
	static let downloadRequestPath = \FileDownloadRequest.constructionSite
	var file: File? { return image }
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
