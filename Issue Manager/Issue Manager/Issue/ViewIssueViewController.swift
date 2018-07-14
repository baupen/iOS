// Created by Julian Dunskus

import UIKit

class ViewIssueViewController: UITableViewController, LoadedViewController {
	typealias Localization = L10n.ViewIssue
	
	static let storyboardID = "View Issue"
	
	@IBOutlet var iconView: TrilinearImageView!
	@IBOutlet var numberLabel: UILabel!
	@IBOutlet var markButton: UIButton!
	@IBOutlet var clientModeLabel: UILabel!
	
	@IBOutlet var craftsmanTradeLabel: UILabel!
	@IBOutlet var craftsmanNameLabel: UILabel!
	
	@IBOutlet var descriptionLabel: UILabel!
	@IBOutlet var statusLabel: UILabel!
	
	@IBOutlet var summaryLabel: UILabel!
	@IBOutlet var completeButton: UIButton!
	@IBOutlet var rejectButton: UIButton!
	@IBOutlet var acceptButton: UIButton!
	@IBOutlet var reopenButton: UIButton!
	
	@IBAction func markIssue() {
		issue.mark()
		update()
	}
	
	@IBAction func revertResponse() {
		issue.revertResponse()
		update()
	}
	
	@IBAction func reviewIssue() {
		issue.review()
		update()
	}
	
	@IBAction func revertReview() {
		issue.revertReview()
		update()
	}
	
	var issue: Issue! {
		didSet {
			update()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	func update() {
		guard isViewLoaded, let issue = issue else { return }
		
		iconView.image = issue.status.simplified.flatIcon
		numberLabel.setText(to: issue.number.map { "#\($0)" }, fallback: L10n.Issue.unregistered)
		markButton.setImage(issue.isMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		clientModeLabel.text = issue.wasAddedWithClient ? L10n.Issue.IsClientMode.true : L10n.Issue.IsClientMode.false
		
		let craftsman = issue.craftsman.flatMap { Client.shared.storage.craftsmen[$0] }
		craftsmanTradeLabel.setText(to: craftsman?.trade, fallback: L10n.Issue.noCraftsman)
		craftsmanNameLabel.setText(to: craftsman?.name, fallback: L10n.Issue.noCraftsman)
		
		descriptionLabel.setText(to: issue.description, fallback: L10n.Issue.noDescription)
		statusLabel.text = issue.status.localizedMultilineDescription
		
		let status = issue.status.simplified
		completeButton.isShown = status == .registered
		rejectButton.isShown = status == .responded
		acceptButton.isShown = status == .responded
		reopenButton.isShown = status == .reviewed
		
		switch status {
		case .new:
			break // shouldn't happen anyway after adding edit view
		case .registered:
			summaryLabel.text = Localization.Summary.noResponse
		case .responded:
			summaryLabel.text = Localization.Summary.hasResponse
		case .reviewed:
			summaryLabel.text = Localization.Summary.reviewed
		}
		
		tableView.performBatchUpdates({}) // invalidate previously calculated row heights
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		// can't localize from storyboard
		switch section {
		case 0: return nil
		case 1: return L10n.Issue.craftsman
		case 2: return Localization.details
		case 3: return Localization.actions
		default: fatalError("unrecognized section \(section)!")
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
}
