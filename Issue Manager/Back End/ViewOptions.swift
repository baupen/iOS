// Created by Julian Dunskus

import UIKit
import UserDefault
import Combine

final class ViewOptions: ObservableObject {
	static let shared = ViewOptions()
	
	var didChange: some Publisher<Void, Never> { didChangeSubject }
	private let didChangeSubject = PassthroughSubject<Void, Never>()
	
	@UserDefault("hiddenStatuses")
	private static var hiddenStatuses: [Issue.Status.Simplified] = []
	
	@Published var visibleStatuses = Issue.allStatuses.subtracting(ViewOptions.hiddenStatuses) {
		didSet {
			Self.hiddenStatuses = .init(Issue.allStatuses.subtracting(visibleStatuses))
			didChangeSubject.send()
		}
	}
	
	@UserDefault("isInClientMode")
	private static var isInClientMode = false
	
	@Published var isInClientMode = ViewOptions.isInClientMode {
		didSet {
			Self.isInClientMode = isInClientMode
			didChangeSubject.send()
		}
	}
	
	var isFiltering: Bool {
		isInClientMode || visibleStatuses != Issue.allStatuses
	}
	
	init() {}
	
	init(visibleStatuses: Set<Issue.Status.Simplified> = [], isInClientMode: Bool = false) {
		self.visibleStatuses = visibleStatuses
		self.isInClientMode = isInClientMode
	}
}
