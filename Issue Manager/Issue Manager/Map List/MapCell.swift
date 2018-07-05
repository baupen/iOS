// Created by Julian Dunskus

import UIKit

class MapCell: UITableViewCell, LoadedTableCell {
	typealias Localization = L10n.MapList.MapSummary
	
	static let reuseID = "Map Cell"
	
	@IBOutlet weak var nameLabel: UILabel?
	@IBOutlet var openIssuesLabel: UILabel?
	
	var map: Map? {
		didSet {
			reload()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		reload()
	}
	
	func reload() {
		guard let map = map else { return }
		nameLabel?.text = map.name
		let openIssues = map.allIssues().lazy.filter { !$0.isReviewed }
		openIssuesLabel?.text = Localization.openIssues(String(openIssues.count))
	}
}
