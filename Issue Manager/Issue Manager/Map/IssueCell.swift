// Created by Julian Dunskus

import UIKit

class IssueCell: UITableViewCell, LoadedTableCell {
	typealias Localization = L10n.Issue
	
	static let reuseID = "Issue Cell"
	
	@IBOutlet var markButton: UIButton!
	@IBOutlet var numberLabel: UILabel!
	@IBOutlet var descriptionLabel: UILabel!
	@IBOutlet var tradeLabel: UILabel!
	@IBOutlet var iconView: UIImageView!
	
	@IBOutlet var expandedView: UIView!
	@IBOutlet var showInMapButton: UIButton!
	@IBOutlet var expandedDescriptionLabel: UILabel!
	@IBOutlet var craftsmanLabel: UILabel!
	@IBOutlet var clientModeLabel: UILabel!
	@IBOutlet var statusLabel: UILabel!
	
	@IBAction func markPressed() {
		issue.mark()
		update()
	}
	
	@IBAction func showInMapPressed() {
		delegate?.zoomMap(to: issue)
	}
	
	weak var delegate: IssueCellDelegate?
	
	var issue: Issue! {
		didSet {
			update()
		}
	}
	
	override var isHighlighted: Bool {
		didSet {
			updateVisibility()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectedBackgroundView = UIView() <- {
			$0.backgroundColor = UIColor.main.withAlphaComponent(0.2)
		}
	}
	
	override func layoutSubviews() {
		updateVisibility()
		
		super.layoutSubviews()
	}
	
	func updateVisibility() {
		tradeLabel.isHidden = isHighlighted || frame.width < 500 // arguably arbitrary
		descriptionLabel.isHidden = isHighlighted
	}
	
	func update() {
		markButton.setImage(issue.isMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		
		iconView.image = issue.status.simplified.flatIcon
		
		numberLabel.setText(to: issue.number.map { "#\($0)" }, fallback: Localization.unregistered)
		
		descriptionLabel.setText(to: issue.description, fallback: Localization.noDescription)
		expandedDescriptionLabel.setText(to: issue.description, fallback: Localization.noDescription)
		
		showInMapButton.isEnabled = issue.position != nil
		
		let craftsman = issue.craftsman.flatMap { Client.shared.storage.craftsmen[$0] }
		tradeLabel.setText(to: craftsman?.trade, fallback: Localization.noCraftsman)
		craftsmanLabel.setText(to: craftsman.map { "\($0.name)\n\($0.trade)" }, fallback: Localization.noCraftsman)
		
		clientModeLabel.text = issue.wasAddedWithClient ? Localization.IsClientMode.true : Localization.IsClientMode.false
		
		statusLabel.text = issue.status.localizedMultilineDescription
	}
}

protocol IssueCellDelegate: AnyObject {
	func zoomMap(to issue: Issue)
}
