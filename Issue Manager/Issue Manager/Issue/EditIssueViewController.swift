// Created by Julian Dunskus

import UIKit

class EditIssueViewController: UITableViewController, LoadedViewController {
	typealias Localization = L10n.ViewIssue
	
	static let storyboardID = "Edit Issue"
	
	@IBOutlet var markButton: UIButton!
	@IBOutlet var clientModeLabel: UILabel!
	
	@IBOutlet var craftsmanTradeCell: UITableViewCell!
	@IBOutlet var craftsmanTradeLabel: UILabel!
	@IBOutlet var craftsmanNameCell: UITableViewCell!
	@IBOutlet var craftsmanNameLabel: UILabel!
	
	@IBOutlet var descriptionCell: UITableViewCell!
	@IBOutlet var descriptionField: UITextField!
	@IBOutlet var suggestionsHeight: NSLayoutConstraint!
	@IBOutlet var suggestionsTableView: UITableView!
	
	@IBAction func markIssue() {
		isIssueMarked.toggle()
	}
	
	@IBAction func descriptionBeganEditing() {
		// make suggestions visible
		let indexPath = tableView.indexPath(for: descriptionCell)!
		// after the table view scrolls by itself
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
			self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
		}
	}
	
	@IBAction func descriptionChanged() {
		suggestionsHandler.currentDescription = descriptionField.text
	}
	
	var issue: Issue! {
		didSet { update() }
	}
	
	var isCreating = false
	
	private var isIssueMarked = false {
		didSet {
			guard isViewLoaded else { return }
			
			markButton.setImage(isIssueMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		}
	}
	
	private var trade: String? {
		didSet {
			craftsmanTradeLabel.setText(to: craftsman?.trade, fallback: Localization.noTrade)
			suggestionsHandler.trade = trade
		}
	}
	
	private var craftsman: Craftsman? {
		didSet {
			craftsmanNameLabel.setText(to: craftsman?.name, fallback: L10n.Issue.noCraftsman)
			trade = craftsman?.trade
		}
	}
	
	private var suggestionsHandler = SuggestionsHandler()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		suggestionsHeight.constant = SuggestionsHandler.intrinsicHeight
		suggestionsHandler.tableView = suggestionsTableView
		suggestionsHandler.delegate = self
		
		update()
	}
	
	// only call this when absolutely necessary; overwrites content in text fields
	private func update() {
		assert(issue?.isRegistered != true)
		guard isViewLoaded else { return }
		
		navigationItem.title = isCreating ? Localization.titleCreating : Localization.titleEditing
		
		let wasAddedWithClient = issue?.wasAddedWithClient ?? defaults.isInClientMode
		clientModeLabel.text = wasAddedWithClient ? L10n.Issue.IsClientMode.true : L10n.Issue.IsClientMode.false
		
		isIssueMarked = issue?.isMarked ?? false
		
		craftsman = issue?.accessCraftsman()
		
		descriptionField.text = issue?.description
		descriptionChanged()
		
		// TODO image
	}
	
	private func save() {
		func update(_ issue: Issue) {
			issue.isMarked = isIssueMarked
			issue.craftsman = craftsman?.id
			issue.description = descriptionField.text
			// TODO image
		}
		
		if isCreating {
			update(issue)
		} else {
			issue.change(transform: update)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "cancel":
			break
		case "save":
			save()
		default:
			fatalError("unrecognized segue named \(segue.identifier ?? "<no identifier>")")
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		// can't localize from storyboard
		switch section {
		case 0: return nil
		case 1: return Localization.image
		case 2: return Localization.craftsman
		case 3: return Localization.description
		default: fatalError("unrecognized section \(section)!")
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		return [craftsmanNameCell, craftsmanTradeCell].contains(tableView.cellForRow(at: indexPath)) ? indexPath : nil
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch tableView.cellForRow(at: indexPath)! {
		case craftsmanNameCell:
			break
		case craftsmanTradeCell:
			break
		default:
			fatalError("unselectable row at \(indexPath) selected!")
		}
	}
}

extension EditIssueViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
}

extension EditIssueViewController: SuggestionsHandlerDelegate {
	func use(_ suggestion: Suggestion) {
		descriptionField.text = suggestion.text
	}
}
