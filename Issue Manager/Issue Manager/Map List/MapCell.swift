// Created by Julian Dunskus

import UIKit

class MapCell: UITableViewCell, LoadedTableCell {
	typealias Localization = L10n.MapList.MapSummary
	
	static let reuseID = "Map Cell"
	
	@IBOutlet weak var nameLabel: UILabel?
	@IBOutlet var openIssuesLabel: UILabel?
	@IBOutlet var issueBadge: IssueBadge!
	
	var map: Map? {
		didSet {
			reload()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		// if i do this via `appearance()` the background disappears when going from highlighted to selected
		selectedBackgroundView = UIView() <- {
			$0.backgroundColor = .main
		}
		
		reload()
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
	
	func reload() {
		guard let map = map else { return }
		nameLabel?.text = map.name
		let openIssues = map.allIssues().lazy.filter { !$0.isReviewed }
		openIssuesLabel?.text = Localization.openIssues(String(openIssues.count))
		issueBadge.source = map
	}
}
