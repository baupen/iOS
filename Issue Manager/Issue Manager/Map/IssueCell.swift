// Created by Julian Dunskus

import UIKit

class IssueCell: UITableViewCell, LoadedTableCell {
	typealias Localization = L10n.Map.IssueList
	
	static let reuseID = "Issue Cell"
	
	@IBOutlet var markButton: UIButton!
	@IBOutlet var numberLabel: UILabel!
	@IBOutlet var descriptionLabel: UILabel!
	@IBOutlet var tradeLabel: UILabel!
	
	@IBAction func markButtonPressed() {
		issue.mark()
		update()
	}
	
	var issue: Issue! {
		didSet {
			update()
		}
	}
	
	override func layoutSubviews() {
		tradeLabel.isHidden = frame.width < 500 // arguably arbitrary
		
		super.layoutSubviews()
	}
	
	func update() {
		markButton.setImage(issue.isMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		numberLabel.setText(to: issue.number.map { "#\($0)" }, fallback: Localization.unregistered)
		descriptionLabel.setText(to: issue.description, fallback: Localization.noDescription)
		
		let craftsman = issue.craftsman.flatMap { Client.shared.storage.craftsmen[$0] }
		tradeLabel.setText(to: craftsman?.trade, fallback: Localization.noCraftsman)
	}
}

fileprivate extension UILabel {
	func setText(to text: String?, fallback: String) {
		self.text = text ?? fallback
		self.alpha = text != nil ? 1 : 0.5
	}
}
