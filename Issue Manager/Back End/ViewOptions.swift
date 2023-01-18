// Created by Julian Dunskus

import UIKit
import UserDefault
import Combine

final class ViewOptions: ObservableObject {
	static let shared = ViewOptions()
	
	var didChange: some Publisher<Void, Never> { _didChange }
	private let _didChange = PassthroughSubject<Void, Never>()
	
	@UserDefault("hiddenStatuses")
	private static var hiddenStatuses: [Issue.Status.Simplified] = []
	
	@Published var visibleStatuses = Issue.allStatuses.subtracting(ViewOptions.hiddenStatuses) {
		didSet {
			Self.hiddenStatuses = .init(Issue.allStatuses.subtracting(visibleStatuses))
			_didChange.send()
		}
	}
	
	@UserDefault("isInClientMode")
	private static var isInClientMode = false
	
	@Published var isInClientMode = ViewOptions.isInClientMode {
		didSet {
			Self.isInClientMode = isInClientMode
			_didChange.send()
		}
	}
	
	@UserDefault("hiddenCraftsmen")
	private static var hiddenCraftsmen: Set<Craftsman.ID?> = []
	
	@Published var hiddenCraftsmen = ViewOptions.hiddenCraftsmen {
		didSet {
			Self.hiddenCraftsmen = hiddenCraftsmen
			_didChange.send()
		}
	}
	
	func onlyCraftsman(in site: ConstructionSite) -> Craftsman.ID? {
		let all = Repository.read(site.craftsmen
			.select([Craftsman.Meta.Columns.id], as: Craftsman.ID.self)
			.fetchAll
		)
		let shown = all.filter { !hiddenCraftsmen.contains($0) }
		guard shown.count == 1 else { return nil }
		return shown.first!
	}
	
	var isFiltering: Bool {
		isInClientMode
		|| visibleStatuses != Issue.allStatuses
		|| !hiddenCraftsmen.isEmpty
	}
	
	init() {}
	
	// for previews
	init(
		visibleStatuses: Set<Issue.Status.Simplified> = [],
		isInClientMode: Bool = false,
		hiddenCraftsmen: Set<Craftsman.ID> = []
	) {
		self.visibleStatuses = visibleStatuses
		self.isInClientMode = isInClientMode
		self.hiddenCraftsmen = hiddenCraftsmen
	}
}
