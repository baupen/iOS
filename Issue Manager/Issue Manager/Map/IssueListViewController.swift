// Created by Julian Dunskus

import UIKit

class IssueListViewController: UIViewController {
	typealias Localization = L10n.Map.IssueList
	
	@IBOutlet var summaryLabel: UILabel!
	
	var map: Map? {
		didSet {
			update()
		}
	}
	var issues: [Issue] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	func update() {
		guard isViewLoaded, let map = map else { return }
		
		issues = Array(map.allIssues())
		let openIssues = issues.lazy.filter { !$0.isReviewed }.count
		summaryLabel.text = Localization.summary(String(openIssues), String(issues.count))
	}
}
