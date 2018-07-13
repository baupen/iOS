// Created by Julian Dunskus

import UIKit

class ViewIssueViewController: UITableViewController, LoadedViewController {
	typealias Localization = L10n.Issue
	
	static let storyboardID = "View Issue"
	
	@IBOutlet var markButton: UIButton!
	@IBOutlet var numberLabel: UILabel!
	@IBOutlet var iconView: TrilinearImageView!
	@IBOutlet var clientModeLabel: UILabel!
	@IBOutlet var descriptionLabel: UILabel!
	@IBOutlet var craftsmanNameLabel: UILabel!
	@IBOutlet var craftsmanTradeLabel: UILabel!
	@IBOutlet var statusLabel: UILabel!
	
	@IBAction func markPressed() {
		issue.mark()
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
		
		markButton.setImage(issue.isMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		iconView.image = issue.status.simplified.flatIcon
		numberLabel.setText(to: issue.number.map { "#\($0)" }, fallback: Localization.unregistered)
		
		clientModeLabel.text = issue.wasAddedWithClient ? Localization.IsClientMode.true : Localization.IsClientMode.false
		
		let craftsman = issue.craftsman.flatMap { Client.shared.storage.craftsmen[$0] }
		craftsmanNameLabel.setText(to: craftsman?.name, fallback: Localization.noCraftsman)
		craftsmanTradeLabel.setText(to: craftsman?.trade, fallback: Localization.noCraftsman)
		
		descriptionLabel.setText(to: issue.description, fallback: Localization.noDescription)
		
		statusLabel.text = issue.status.localizedMultilineDescription
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		// can't localize from storyboard
		switch section {
		case 0: return nil
		case 1: return Localization.craftsman
		case 2: return nil
		default: fatalError("unrecognized section \(section)!")
		}
	}
}
