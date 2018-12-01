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
	@IBOutlet var actionsView: UIStackView!
	
	@IBAction func markPressed() {
		issue.mark()
		Haptics.generateFeedback(.strong)
		update()
	}
	
	@IBAction func showInMap() {
		delegate?.zoomMap(to: issue)
	}
	
	@IBAction func showDetails() {
		delegate?.showDetails(for: issue)
	}
	
	weak var delegate: IssueCellDelegate?
	
	var issue: Issue! {
		didSet { update() }
	}
	
	override var isHighlighted: Bool {
		didSet { updateVisibility() }
	}
	
	private var isCompact: Bool {
		return frame.width < 500
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectedBackgroundView = UIView() <- {
			$0.backgroundColor = UIColor.main.withAlphaComponent(0.2)
		}
	}
	
	override func layoutSubviews() {
		updateVisibility()
		actionsView.axis = isCompact ? .vertical : .horizontal
		
		super.layoutSubviews()
	}
	
	func updateVisibility() {
		tradeLabel.isHidden = isHighlighted || isCompact
		descriptionLabel.isHidden = isHighlighted
	}
	
	func update() {
		markButton.setImage(issue.isMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		
		iconView.image = issue.status.simplified.flatIcon
		
		numberLabel.setText(to: issue.number.map { "#\($0)" }, fallback: Localization.unregistered)
		
		descriptionLabel.setText(to: issue.description?.nonEmptyOptional, fallback: Localization.noDescription)
		expandedDescriptionLabel.setText(to: issue.description?.nonEmptyOptional, fallback: Localization.noDescription)
		
		showInMapButton.isEnabled = issue.position != nil
		
		let craftsman = issue.accessCraftsman()
		tradeLabel.setText(to: craftsman?.trade, fallback: Localization.noCraftsman)
		craftsmanLabel.setText(to: craftsman.map { "\($0.name)\n\($0.trade)" }, fallback: Localization.noCraftsman)
		
		clientModeLabel.text = issue.wasAddedWithClient ? Localization.IsClientMode.true : Localization.IsClientMode.false
		
		statusLabel.text = issue.status.localizedMultilineDescription
	}
}

protocol IssueCellDelegate: AnyObject {
	func zoomMap(to issue: Issue)
	func showDetails(for issue: Issue)
}
