// Created by Julian Dunskus

import UIKit
import HandyOperators

final class IssueCell: UITableViewCell, Reusable {
	typealias Localization = L10n.Issue
	
	@IBOutlet private var markButton: UIButton!
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var descriptionLabel: UILabel!
	@IBOutlet private var tradeLabel: UILabel!
	@IBOutlet private var iconView: UIImageView!
	
	@IBOutlet private var expandedView: UIView!
	@IBOutlet private var showInMapButton: UIButton!
	@IBOutlet private var expandedDescriptionLabel: UILabel!
	@IBOutlet private var craftsmanLabel: UILabel!
	@IBOutlet private var clientModeLabel: UILabel!
	@IBOutlet private var statusLabel: UILabel!
	@IBOutlet private var actionsView: UIStackView!
	
	@IBAction func markPressed() {
		issue.isMarked.toggle()
		Task { try await issue.saveAndSync() }
		Haptics.mediumImpact.impactOccurred()
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
	
	override var isSelected: Bool {
		didSet { updateVisibility() }
	}
	
	private var isCompact: Bool {
		frame.width < 500
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
		tradeLabel.isHidden = isSelected || isCompact
	}
	
	func update() {
		updateVisibility()
		
		markButton.setImage(issue.isMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		
		iconView.image = issue.status.simplified.flatIcon
		
		numberLabel.setText(to: issue.number.map { "#\($0)" }, fallback: Localization.unregistered)
		
		descriptionLabel.setText(to: issue.description?.nonEmptyOptional, fallback: Localization.noDescription)
		expandedDescriptionLabel.setText(to: issue.description?.nonEmptyOptional, fallback: Localization.noDescription)
		
		showInMapButton.isEnabled = issue.position != nil
		
		let craftsman = Repository.read(issue.craftsman)
		tradeLabel.setText(
			to: craftsman?.trade,
			fallback: Localization.noCraftsman
		)
		craftsmanLabel.setText(
			to: craftsman.map { "\($0.company)\n\($0.trade)" },
			fallback: Localization.noCraftsman
		)
		
		statusLabel.text = issue.status.makeLocalizedMultilineDescription()
		
		clientModeLabel.isShown = issue.wasAddedWithClient
	}
}

@MainActor
protocol IssueCellDelegate: AnyObject {
	func zoomMap(to issue: Issue)
	func showDetails(for issue: Issue)
}
