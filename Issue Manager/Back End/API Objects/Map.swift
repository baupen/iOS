// Created by Julian Dunskus

import Foundation

struct Map {
	let meta: ObjectMeta<Map>
	let children: [ID<Map>]
	let sectors: [Sector]
	let sectorFrame: Rectangle?
	private(set) var issues: [ID<Issue>]
	let file: File?
	let name: String
	let constructionSiteID: ID<ConstructionSite>
	
	mutating func addIfMissing(_ issue: Issue) {
		guard !issues.contains(issue.id) else { return }
		add(issue)
	}
	
	mutating func add(_ issue: Issue) {
		issues.append(issue.id)
		Repository.shared.save(self)
	}
	
	mutating func remove(_ id: ID<Issue>) {
		issues.removeAll { $0 == id }
		Repository.shared.save(self)
	}
	
	final class Sector: Codable {
		let name: String
		let color: Color
		let points: [Point]
	}
}

extension Map: APIObject {}

extension Map: FileContainer {
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
}

extension Map: MapHolder {
	func recursiveChildren() -> [Map] {
		return [self] + childMaps().flatMap { $0.recursiveChildren() }
	}
}

extension Map {
	var hasChildren: Bool {
		return !children.isEmpty
	}
	
	func allIssues() -> [Issue] {
		if defaults.isInClientMode {
			return issues.lazy
				.compactMap(Repository.shared.issue)
				.filter { $0.wasAddedWithClient }
		} else {
			return issues.compactMap(Repository.shared.issue)
		}
	}
	
	func accessSite() -> ConstructionSite {
		return Repository.shared.site(constructionSiteID)!
	}
}
