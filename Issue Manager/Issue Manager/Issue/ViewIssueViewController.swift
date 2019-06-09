// Created by Julian Dunskus

import UIKit

final class ViewIssueViewController: UITableViewController, Reusable {
	typealias Localization = L10n.ViewIssue
	
	@IBOutlet private var iconView: TrilinearImageView!
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var markButton: UIButton!
	@IBOutlet private var clientModeLabel: UILabel!
	
	@IBOutlet private var imageView: UIImageView!
	
	@IBOutlet private var craftsmanTradeLabel: UILabel!
	@IBOutlet private var craftsmanNameLabel: UILabel!
	
	@IBOutlet private var descriptionLabel: UILabel!
	@IBOutlet private var statusLabel: UILabel!
	
	@IBOutlet private var summaryLabel: UILabel!
	@IBOutlet private var completeButton: UIButton!
	@IBOutlet private var rejectButton: UIButton!
	@IBOutlet private var acceptButton: UIButton!
	@IBOutlet private var reopenButton: UIButton!
	
	@IBAction func markIssue() {
		issue.mark()
		Haptics.mediumImpact.impactOccurred()
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
		didSet { update() }
	}
	
	private var image: UIImage? {
		didSet { imageView.image = image }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		tableView.reloadData()
	}
	
	func update() {
		guard isViewLoaded, let issue = issue else { return }
		
		iconView.image = issue.status.simplified.flatIcon
		numberLabel.setText(to: issue.number.map { "#\($0)" }, fallback: L10n.Issue.unregistered)
		markButton.setImage(issue.isMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		clientModeLabel.text = issue.wasAddedWithClient ? Localization.IsClientMode.true : Localization.IsClientMode.false
		
		image = issue.image.flatMap {
			// TODO: fall back on localURL for other views
			UIImage(contentsOfFile: Issue.cacheURL(for: $0).path)
		}
		
		let craftsman = Repository.read(issue.craftsman)
		craftsmanTradeLabel.setText(to: craftsman?.trade, fallback: L10n.Issue.noCraftsman)
		craftsmanNameLabel.setText(to: craftsman?.name, fallback: L10n.Issue.noCraftsman)
		
		descriptionLabel.setText(to: issue.description?.nonEmptyOptional, fallback: L10n.Issue.noDescription)
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
		
		tableView.performBatchUpdates(nil) // invalidate previously calculated row heights
	}
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		switch identifier {
		case "lightbox":
			return image != nil
		default:
			return true
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "lightbox":
			let lightboxController = segue.destination as! LightboxViewController
			lightboxController.image = image!
			lightboxController.sourceView = imageView
		default:
			break
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		// can't localize from storyboard
		switch section {
		case 0: return nil
		case 1: return Localization.image
		case 2: return Localization.craftsman
		case 3: return Localization.details
		case 4: return Localization.actions
		default: fatalError("unrecognized section \(section)!")
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
}
