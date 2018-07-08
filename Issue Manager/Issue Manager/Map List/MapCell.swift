// Created by Julian Dunskus

import UIKit

class MapCell: UITableViewCell, LoadedTableCell {
	typealias Localization = L10n.MapList.MapSummary
	
	static let reuseID = "Map Cell"
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet var openIssuesLabel: UILabel!
	@IBOutlet var issueBadge: IssueBadge!
	
	var shouldUseRecursiveIssues = true
	var map: Map! {
		didSet {
			update()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		// if i do this via `appearance()` the background disappears when going from highlighted to selected
		selectedBackgroundView = UIView() <- {
			$0.backgroundColor = .main
		}
	}
	
	override func setHighlighted(_ highlighted: Bool, animated: Bool) {
		issueBadge.keepBackgroundColor {
			super.setHighlighted(highlighted, animated: animated)
		}
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		issueBadge.keepBackgroundColor {
			super.setSelected(selected, animated: animated)
		}
	}
	
	func update() {
		nameLabel!.text = map.name
		
		let issues = shouldUseRecursiveIssues ? map.recursiveIssues() : map.allIssues()
		let openIssueCount = BasicFuture(asyncOn: .global()) {
			issues
				.lazy
				.filter { !$0.isReviewed }
				.count
		}
		openIssueCount.on(.main).then { count in
			self.openIssuesLabel?.text = Localization.openIssues(String(count))
		}
		
		issueBadge.shouldUseRecursiveIssues = shouldUseRecursiveIssues
		issueBadge.holder = map
	}
}