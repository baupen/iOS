// Created by Julian Dunskus

import UIKit

final class EditIssueNavigationController: UINavigationController {
	var editIssueController: EditIssueViewController {
		return topViewController as! EditIssueViewController
	}
}

final class EditIssueViewController: UITableViewController, LoadedViewController {
	typealias Localization = L10n.ViewIssue
	
	static let storyboardID = "Edit Issue"
	
	@IBOutlet var markButton: UIButton!
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var cameraContainerView: CameraContainerView!
	@IBOutlet var cameraView: CameraView!
	@IBOutlet var markupButton: UIButton!
	
	@IBOutlet var craftsmanTradeLabel: UILabel!
	@IBOutlet var craftsmanNameLabel: UILabel!
	
	@IBOutlet var descriptionCell: UITableViewCell!
	@IBOutlet var descriptionField: UITextField!
	@IBOutlet var suggestionsHeight: NSLayoutConstraint!
	@IBOutlet var suggestionsTableView: UITableView!
	
	@IBAction func markIssue() {
		isIssueMarked.toggle()
		Haptics.generateFeedback(.strong)
	}
	
	@IBAction func descriptionBeganEditing() {
		// make suggestions visible
		let indexPath = tableView.indexPath(for: descriptionCell)!
		// after the table view scrolls by itself
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [tableView] in
			tableView!.scrollToRow(at: indexPath, at: .top, animated: true)
		}
	}
	
	@IBAction func descriptionChanged() {
		suggestionsHandler.currentDescription = descriptionField.text
	}
	
	@IBAction func removeImage() {
		image = nil
	}
	
	@IBAction func openImagePicker(_ sender: UIView) {
		guard let picker = cameraView.prepareImagePicker(for: .photoLibrary) else {
			showAlert(
				titled: Localization.CouldNotOpenLibrary.title,
				message: Localization.CouldNotOpenLibrary.message
			)
			return
		}
		picker.modalPresentationStyle = .popover
		let popover = picker.popoverPresentationController!
		popover.sourceView = sender
		popover.sourceRect = sender.bounds
		present(picker, animated: true)
	}
	
	@IBAction func retryCamera() {
		cameraView.configure()
	}
	
	// the markup editor's buttons link to this
	@IBAction func backToIssueEditor(_ segue: UIStoryboardSegue) {}
	
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
			craftsmanTradeLabel.setText(to: trade, fallback: Localization.noTrade)
			suggestionsHandler.trade = trade
			
			if trade != craftsman?.trade {
				if trade != nil, possibleCraftsmen().count == 1 {
					craftsman = possibleCraftsmen()[0]
				} else {
					craftsman = nil
				}
			}
		}
	}
	
	private var craftsman: Craftsman? {
		didSet {
			craftsmanNameLabel.setText(to: craftsman?.name, fallback: L10n.Issue.noCraftsman)
		}
	}
	
	var image: UIImage? {
		didSet {
			hasChangedImage = true
			imageView.image = image
			cameraContainerView.isHidden = image != nil
			markupButton.isEnabled = image != nil
		}
	}
	private var hasChangedImage = false
	
	private var building: Building!
	private var suggestionsHandler = SuggestionsHandler()
	private var originalDescription: String?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		suggestionsHeight.constant = SuggestionsHandler.intrinsicHeight
		suggestionsHandler.tableView = suggestionsTableView
		suggestionsHandler.delegate = self
		
		cameraView.delegate = self
		
		update()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		tableView.reloadData()
	}
	
	// only call this when absolutely necessary; overwrites content in text fields
	private func update() {
		assert(issue?.isRegistered != true)
		guard isViewLoaded else { return }
		
		building = issue.accessMap().accessBuilding()
		
		navigationItem.title = isCreating ? Localization.titleCreating : Localization.titleEditing
		
		isIssueMarked = issue?.isMarked ?? false
		
		craftsman = issue?.accessCraftsman()
		trade = craftsman?.trade
		
		descriptionField.text = issue?.description
		descriptionChanged()
		originalDescription = issue?.description
		
		image = issue.imageFilename.flatMap {
			UIImage(contentsOfFile: Issue.cacheURL(filename: $0).path)
				?? UIImage(contentsOfFile: Issue.localURL(filename: $0).path)
		}
		hasChangedImage = false
	}
	
	private func save() {
		func update(_ issue: Issue) {
			issue.isMarked = isIssueMarked
			issue.craftsman = craftsman?.id
			issue.description = descriptionField.text
			
			if hasChangedImage {
				if let image = image {
					let filename = "\(UUID()).jpg"
					
					let url = Issue.localURL(filename: filename)
					do {
						try image.saveJPEG(to: url)
						issue.imageFilename = filename
					} catch {
						showAlert(titled: Localization.CouldNotSaveImage.title, message: error.localizedFailureReason)
						issue.imageFilename = nil
					}
				} else {
					issue.imageFilename = nil
				}
			}
		}
		
		if isCreating {
			update(issue)
			Client.shared.storage.add(issue)
		} else {
			issue.change(transform: update)
		}
		
		if issue.description != originalDescription {
			SuggestionStorage.shared.used(description: issue.description, forTrade: trade)
		}
	}
	
	func possibleCraftsmen() -> [Craftsman] {
		return building.allCraftsmen()
			.filter { trade == nil || $0.trade == trade }
			.sorted { $0.name < $1.name }
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
		case "cancel":
			break
		case "save":
			save()
		case "delete":
			Client.shared.storage.remove(issue)
		case "lightbox":
			let lightboxController = segue.destination as! LightboxViewController
			lightboxController.image = image!
		case "markup":
			let markupNavController = segue.destination as! MarkupNavigationController
			markupNavController.markupController.image = image!
		case "select trade":
			let selectionController = segue.destination as! SelectionViewController
			selectionController.handler = TradeSelectionHandler(
				in: building,
				currentTrade: trade
			) { self.trade = $0 }.wrapped()
		case "select craftsman":
			let selectionController = segue.destination as! SelectionViewController
			selectionController.handler = CraftsmanSelectionHandler(
				options: possibleCraftsmen(),
				trade: trade,
				current: craftsman
			) { self.craftsman = $0 }.wrapped()
		default:
			fatalError("unrecognized segue named \(segue.identifier ?? "<no identifier>")")
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return isCreating ? 4 : 5 // can't delete issue when creating
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		// can't localize from storyboard
		switch section {
		case 0: return nil
		case 1: return Localization.image
		case 2: return Localization.craftsman
		case 3: return Localization.description
		case 4: return Localization.actions
		default: fatalError("unrecognized section \(section)!")
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
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

extension EditIssueViewController: CameraViewDelegate {
	func cameraFailed(with error: Error) {
		showAlert(titled: Localization.couldNotActivateCamera, message: error.localizedFailureReason)
	}
	
	func pictureFailed(with error: Error) {
		showAlert(titled: Localization.CouldNotTakePicture.title, message: error.localizedFailureReason)
	}
	
	func pictureTaken(_ image: UIImage) {
		self.image = image
	}
	
	func pictureSelected(_ image: UIImage) {
		self.image = image
	}
}

extension UIImage {
	func saveJPEG(to url: URL) throws {
		guard let jpg = jpegData(compressionQuality: 0.75) else {
			throw NSError(localizedDescription: "Could not generate JPEG representation for image!")
		}
		print("Saving file to", url)
		try jpg.write(to: url)
	}
}
