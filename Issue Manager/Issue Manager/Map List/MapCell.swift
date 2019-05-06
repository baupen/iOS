// Created by Julian Dunskus

import UIKit
import Promise

final class MapCell: UITableViewCell, Reusable {
	typealias Localization = L10n.MapList.MapSummary
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet var openIssuesLabel: UILabel!
	@IBOutlet var issueBadge: IssueBadge!
	
	var isRefreshing = false {
		didSet {
			UIView.animate(withDuration: 0.1) {
				self.contentView.alpha = self.isRefreshing ? 0.25 : 1
			}
			
			isUserInteractionEnabled = !isRefreshing
		}
	}
	
	var shouldUseRecursiveIssues = true
	var map: Map! {
		didSet { update() }
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
		
		let issues = Repository.shared.issues(in: map, recursively: shouldUseRecursiveIssues).openIssues
		// async because there could be a lot of issues (e.g. if we're calculating it for a high-level map)
		let openIssueCount = BasicFuture(asyncOn: .global()) {
			Repository.shared.read(issues.fetchCount)
		}
		openIssueCount.on(.main).then { count in
			self.openIssuesLabel?.text = Localization.openIssues(String(count))
		}
		
		issueBadge.shouldUseRecursiveIssues = shouldUseRecursiveIssues
		issueBadge.holder = map
		
		if shouldUseRecursiveIssues, Repository.shared.hasChildren(for: map) {
			accessoryView = nil
			// nil makes it use accessoryType, which is a disclosure indicator
		} else {
			// fake accessory view so we have the same margins as with a disclosure indicator
			accessoryView = UIView() <- {
				$0.frame.size.width = 18 // oof, hardcoded size
				$0.isHidden = true
			}
		} 
	}
}
