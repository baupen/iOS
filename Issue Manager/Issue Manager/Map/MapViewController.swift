// Created by Julian Dunskus

// import ALL the things!
import SwiftUI
import class Combine.AnyCancellable
import SimplePDFKit
import PullToExpand
import CGeometry
import UserDefault
import HandyOperators

final class MapViewController: UIViewController, InstantiableViewController {
	typealias Localization = L10n.Map
	
	static let storyboardName = "Map"
	
	@IBOutlet private var filterItem: UIBarButtonItem!
	@IBOutlet private var addItem: UIBarButtonItem!
	
	@IBOutlet private var fallbackLabel: UILabel!
	@IBOutlet private var pdfContainerView: UIView!
	@IBOutlet private var activityIndicator: UIActivityIndicatorView!
	@IBOutlet private var pullableContainer: UIView!
	@IBOutlet private var pullableView: PullableView!
	@IBOutlet private var issuePositioner: IssuePositioner!
	@IBOutlet private var addUnplacedContainer: UIView!
	
	// the filter popover's done button and the issue editor's reposition button link to this
	@IBAction func backToMap(_ segue: UIStoryboardSegue) {}
	
	// the issue editor & viewers' close buttons link to this
	@IBAction func backToMapCancelling(_ segue: UIStoryboardSegue) {
		cancelAddingIssue() // even if issue editor closed by cancelling
	}
	
	// the issue popovers' done buttons link to this
	@IBAction func backToMapWithUpdates(_ segue: UIStoryboardSegue) {
		updateFromRepository()
	}
	
	@IBAction func beginAddingIssue() {
		guard map?.file != nil else {
			performSegue(withIdentifier: SegueID.createUnplaced.rawValue, sender: nil)
			return
		}
		
		enterPlacementMode()
	}
	
	@IBAction func cancelAddingIssue() {
		UIView.animate(withDuration: 0.25) {
			self.isPlacingIssue = false
		}
		if isMovingIssue {
			// unplaced = don't apply new position
			performSegue(withIdentifier: SegueID.createUnplaced.rawValue, sender: nil)
		}
	}
	
	@IBAction func showStatusFilterEditor(_ sender: UIBarButtonItem) {
		guard let holder else { return } // should be disabled otherwise
		let site = Repository.read(holder.constructionSiteID.get)!
		let craftsmen = Repository.read(site.craftsmen.order(Craftsman.Columns.company).fetchAll)
		let view = ViewOptionsEditor(craftsmen: craftsmen)
		let controller = UIHostingController(rootView: view)
		controller.modalPresentationStyle = .popover
		controller.popoverPresentationController!.barButtonItem = sender
		present(controller, animated: true)
	}
	
	var markers: [IssueMarker] = []
	var markerAlpha: CGFloat = 0.1 {
		didSet { pdfController?.overlayView.alpha = markerAlpha }
	}
	
	var isPlacingIssue = false {
		didSet {
			markerAlpha = isPlacingIssue ? 0.25 : 1
			addItem.isEnabled = !isPlacingIssue
			issuePositioner.isShown = isPlacingIssue
			addUnplacedContainer.isShown = isPlacingIssue && !isMovingIssue
		}
	}
	
	var issueListController: IssueListViewController!
	
	var pdfController: SimplePDFViewController? {
		didSet {
			guard pdfController != oldValue else { return }
			if let old = oldValue {
				old.delegate = nil
				unembed(old)
			}
			if let new = pdfController {
				embed(new, within: pdfContainerView)
			}
		}
	}
	
	var isMovingIssue: Bool { editorForPlacingIssue != nil }
	private var editorForPlacingIssue: EditIssueViewController?
	
	var holder: (any MapHolder)? {
		didSet { update() }
	}
	var map: Map? { holder as? Map }
	
	var issues: [Issue] = []
	
	private var viewOptionsToken: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewOptionsToken = ViewOptions.shared.didChange.sink { [unowned self] in
			issues = (map?.sortedIssues.fetchAll).map(Repository.read) ?? []
			updateMarkers()
			applyViewOptions()
		}
		
		update()
		applyViewOptions()
	}
	
	func applyViewOptions() {
		let options = ViewOptions.shared
		filterItem.image = options.isFiltering ? #imageLiteral(resourceName: "filter_enabled.pdf") : #imageLiteral(resourceName: "filter_disabled.pdf")
		issueListController.visibleStatuses = options.visibleStatuses
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateBarButtonItem()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		pullableView.maxHeight = pullableContainer.frame.height
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		coordinator.animate(alongsideTransition: { context in
			self.updateBarButtonItem()
		})
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.destination {
		case let issueList as IssueListViewController:
			// called in the beginning when the list controller is embedded
			issueListController = issueList
			issueListController.issueCellDelegate = self
			issueListController.pullableView = pullableView
		case let editIssueNav as EditIssueNavigationController:
			guard let segueID = segue.identifier.flatMap(SegueID.init) else {
				fatalError("unrecognized segue to issue editor with identifier '\(segue.identifier ?? "<no id>")'")
			}
			segue.destination.presentationController?.delegate = self
			lazy var position = Issue.Position(
				at: issuePositioner.relativePosition(in: pdfController!.overlayView),
				zoomScale: pdfController!.scrollView.zoomScale / pdfController!.scrollView.minimumZoomScale
			)
			let editController = editIssueNav.editIssueController
			editController.initiateReposition = { [unowned self] in moveIssue(for: $0) }
			if let editorForPlacingIssue {
				self.editorForPlacingIssue = nil
				editController.copySettings(
					from: editorForPlacingIssue,
					movingTo: segueID == .createPlaced ? position : nil // don't move if cancelled
				)
			} else {
				editController.isCreating = true // otherwise we wouldn't be using a segue
				let map = holder as! Map
				switch segueID {
				case .createUnplaced:
					editController.present(Issue(in: map))
				case .createPlaced:
					editController.present(Issue(at: isPlacingIssue ? position : nil, in: map))
				}
			}
		default:
			fatalError("unrecognized segue to \(segue.destination)")
		}
	}
	
	func moveIssue(for editor: EditIssueViewController) {
		editorForPlacingIssue = editor
		enterPlacementMode()
	}
	
	private func enterPlacementMode() {
		guard !isPlacingIssue else { return }
		
		if !pullableView.isCompact {
			pullableView.contract()
		}
		
		issuePositioner.center = CGPoint(x: view.bounds.width, y: 0) // more or less where the add button is
		view.setNeedsLayout()
		
		UIView.animate(withDuration: 0.25) {
			self.isPlacingIssue = true
			self.view.layoutIfNeeded() // centers issue positioner according to constraints
		}
	}
	
	private func updateBarButtonItem() {
		switch parent {
		case is MasterNavigationController:
			navigationItem.leftBarButtonItem = nil
		case is DetailNavigationController:
			navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		default:
			break // ignore
		}
	}
	
	func update() {
		guard isViewLoaded else { return }
		
		isPlacingIssue = false
		
		navigationItem.title = holder?.name ?? Localization.title
		
		addItem.isEnabled = map != nil
		filterItem.isEnabled = holder != nil
		
		issues = (map?.sortedIssues.fetchAll).map(Repository.read) ?? []
		
		issueListController.map = map
		pullableView.isHidden = map == nil
		
		if let map = map, let file = map.file {
			let url = Map.localURL(for: file)
			asyncLoadPDF(for: map, at: url)
		} else {
			pdfController = nil
			if let holder = holder {
				fallbackLabel.text = Localization.noPdf(holder.name)
			} else {
				fallbackLabel.text = Localization.noMapSelected
			}
		}
	}
	
	private var currentLoadingTask: Task<Void, Never>?
	func asyncLoadPDF(for map: Map, at url: URL) {
		pdfController = nil
		fallbackLabel.text = Localization.pdfLoading
		activityIndicator.startAnimating()
		
		currentLoadingTask?.cancel()
		currentLoadingTask = Task {
			// download explicitly just in case it's not there yet
			try? await map.downloadFileIfNeeded() // errors are fine (e.g. bad network)
			
			let page: PDFKitPage
			do {
				page = try await Task.detached(priority: .userInitiated) {
					UncheckedSendable(try PDFKitDocument(at: url).page(0))
				}.value.value
			} catch {
				guard !Task.isCancelled else { return }
				error.printDetails(context: "Error while loading PDF!")
				self.activityIndicator.stopAnimating()
				self.fallbackLabel.text = Localization.couldNotLoad
				return
			}
			
			guard !Task.isCancelled else { return }
			
			self.pdfController = SimplePDFViewController() <- {
				$0.delegate = self
				$0.backgroundColor = .white // some maps have a transparent background and black elements, so they need a bright background
				$0.display(page) // should be set after the background color (technically a race condition otherwise)
				$0.overlayView.alpha = self.markerAlpha
				$0.overlayView.backgroundColor = .darkOverlay
				$0.additionalSafeAreaInsets.bottom += self.pullableView.minHeight
					+ 8 // for symmetry
			}
			self.updateMarkers()
		}
	}
	
	private func updateMarkers() {
		guard let pdfController = pdfController else { return }
		
		pdfController.view.layoutIfNeeded()
		
		markers.forEach { $0.removeFromSuperview() }
		markers = issues.filter { $0.position != nil }.map { issue in
			IssueMarker(issue: issue) <- {
				$0.zoomScale = pdfController.scrollView.zoomScale
				$0.buttonAction = { [unowned self] in
					self.showDetails(for: issue)
				}
			}
		}
		markers.forEach(pdfController.overlayView.addSubview)
		
		updateMarkerAppearance()
	}
	
	func updateMarkerAppearance() {
		for marker in markers {
			marker.update()
		}
	}
	
	func showDetails(for issue: Issue) {
		guard let issue = Repository.read(issue.id.get) else {
			// there's a time between uploading an issue (giving it a new id) and uploading its image (after which we'd refresh our view) during which we're displaying an outdated id.
			updateFromRepository() // must have been showing outdated data
			return
		}
		
		let viewController = issue.isRegistered
		? ViewIssueViewController.self.instantiate()! <- { $0.issue = issue }
		: EditIssueViewController.self.instantiate()! <- {
			$0.present(issue)
			$0.initiateReposition = { [unowned self] in moveIssue(for: $0) }
		}
		
		let navController = UINavigationController(rootViewController: viewController)
			<- { $0.modalPresentationStyle = .formSheet }
		
		present(navController, animated: true)
		navController.presentationController?.delegate = self
	}
	
	private enum SegueID: String {
		case createPlaced, createUnplaced
	}
}

extension MapViewController: SimplePDFViewControllerDelegate {
	func pdfZoomed(to scale: CGFloat) {
		markers.forEach { $0.zoomScale = scale }
	}
	
	func pdfFinishedLoading() {
		activityIndicator.stopAnimating()
		fallbackLabel.text = nil
		
		markerAlpha = 1
	}
}

extension MapViewController: IssueCellDelegate {
	func zoomMap(to issue: Issue) {
		guard let position = issue.position else {
			print("attempting to zoom to issue with no position!")
			return
		}
		
		pullableView.contract()
		
		let pdfController = self.pdfController!
		let marker = markers.first { $0.issue.id == issue.id }!
		let size = pdfController.contentView.bounds.size * CGFloat(position.zoomScale)
		let centeredRect = CGRect(
			origin: marker.center - CGVector(size) / 2,
			size: size
		)
		pdfController.scrollView.zoom(to: centeredRect, animated: true)
		
		// scale up and down to draw attention (important if can't center because scale too small)
		let originalTransform = marker.transform
		UIView.animateKeyframes(withDuration: 0.5, delay: 0.1, animations: {
			UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
				marker.transform = originalTransform.scaledBy(x: 2, y: 2)
			}
			UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
				marker.transform = originalTransform
			}
		})
	}
}

extension MapViewController: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		updateFromRepository()
	}
	
	func updateFromRepository() {
		guard let map = holder as? Map else { return }
		
		cancelAddingIssue() // done (if started)
		
		issues = Repository.read(map.sortedIssues.fetchAll)
		updateMarkers()
		issueListController.update()
		
		Task {
			guard let splitController = self.splitViewController else { return }
			let mainController = splitController as! MainViewController
			for viewController in mainController.masterNav.viewControllers {
				(viewController as? MapListViewController)?.reload(map)
			}
		}
	}
}

extension Issue {
	static let allStatuses = Set(Issue.Status.Simplified.allCases)
}

extension Issue.Status.Simplified: DefaultsValueConvertible {
	typealias DefaultsRepresentation = RawValue
}
