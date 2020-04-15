// Created by Julian Dunskus

// import ALL the things!
import UIKit
import SimplePDFKit
import PullToExpand
import Promise
import CGeometry

final class MapViewController: UIViewController, Reusable {
	typealias Localization = L10n.Map
	
	@IBOutlet private var filterItem: UIBarButtonItem!
	@IBOutlet private var addItem: UIBarButtonItem!
	
	@IBOutlet private var fallbackLabel: UILabel!
	@IBOutlet private var pdfContainerView: UIView!
	@IBOutlet private var activityIndicator: UIActivityIndicatorView!
	@IBOutlet private var pullableContainer: UIView!
	@IBOutlet private var pullableView: PullableView!
	@IBOutlet private var issuePositioner: IssuePositioner!
	
	// the filter popover's done button and the add marker popover's cancel button link to this
	@IBAction func backToMap(_ segue: UIStoryboardSegue) {
		cancelAddingIssue() // even if issue editor closed by cancelling
	}
	
	// the issue popovers' done buttons link to this
	@IBAction func backToMapWithUpdates(_ segue: UIStoryboardSegue) {
		didReturnFromModal()
	}
	
	@IBAction func beginAddingIssue() {
		guard map?.file != nil else {
			performSegue(withIdentifier: "create issue", sender: nil)
			return
		}
		
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
	
	@IBAction func cancelAddingIssue() {
		UIView.animate(withDuration: 0.25) {
			self.isPlacingIssue = false
		}
	}
	
	var markers: [IssueMarker] = []
	var markerAlpha: CGFloat = 0.1 {
		didSet { pdfController?.overlayView.alpha = markerAlpha }
	}
	
	let sectorView = UIView(frame: CGRect(origin: .zero, size: .one)) <- {
		$0.autoresizingMask = .flexibleSize
	}
	var sectorViews: [SectorView] = []
	
	var isPlacingIssue = false {
		didSet {
			markerAlpha = isPlacingIssue ? 0.25 : 1
			addItem.isEnabled = !isPlacingIssue
			issuePositioner.isHidden = !isPlacingIssue
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
	
	var holder: MapHolder? {
		didSet { update() }
	}
	var map: Map? { holder as? Map }
	
	var issues: [Issue] = []
	
	var visibleStatuses = Issue.allStatuses {
		didSet {
			updateMarkerAppearance()
			filterItem.image = visibleStatuses == Issue.allStatuses ? #imageLiteral(resourceName: "filter_disabled.pdf") : #imageLiteral(resourceName: "filter_enabled.pdf")
			issueListController.visibleStatuses = visibleStatuses
			defaults.hiddenStatuses = Array(Issue.allStatuses.subtracting(visibleStatuses))
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		visibleStatuses = Issue.allStatuses.subtracting(defaults.hiddenStatuses)
		update()
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
		case let statusFilterNav as StatusFilterNavigationController:
			let filterController = statusFilterNav.statusFilterController
			filterController.selected = visibleStatuses
			filterController.delegate = self
			segue.destination.presentationController?.delegate = self
		case let editIssueNav as EditIssueNavigationController:
			let editController = editIssueNav.editIssueController
			editController.isCreating = true // otherwise we wouldn't be using a segue
			if isPlacingIssue {
				let map = holder as! Map
				let position = Issue.Position(
					at: issuePositioner.relativePosition(in: pdfController!.overlayView),
					zoomScale: pdfController!.scrollView.zoomScale / pdfController!.scrollView.minimumZoomScale,
					in: map.file!
				)
				editController.present(Issue(at: isPlacingIssue ? position : nil, in: map))
			} else {
				editController.present(Issue(in: holder as! Map))
			}
			segue.destination.presentationController?.delegate = self
		default:
			fatalError("unrecognized segue to \(segue.destination)")
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
		
		issues = (map?.sortedIssues.fetchAll).map(Repository.read) ?? []
		
		sectorViews.forEach { $0.removeFromSuperview() }
		sectorViews = map?.sectors.map(SectorView.init) ?? []
		sectorViews.forEach { $0.delegate = self }
		sectorViews.forEach(sectorView.addSubview)
		
		issueListController.map = map
		pullableView.isHidden = map == nil
		
		if let map = map, let file = map.file {
			let url = Map.cacheURL(for: file)
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
	
	private var currentLoadingTaskID: UUID!
	func asyncLoadPDF(for map: Map, at url: URL) {
		let page = Future
			.init(asyncOn: .global(qos: .userInitiated), map.downloadFile) // download explicitly just in case it's not there yet
			.mapError { _ in .fulfilled } // errors are fine (e.g. bad network)
			.map { _ in try PDFDocument(at: url).page(0) }
			.on(.main)
		
		pdfController = nil
		fallbackLabel.text = Localization.pdfLoading
		activityIndicator.startAnimating()
		
		let taskID = UUID()
		currentLoadingTaskID = taskID
		
		page.then { page in
			guard taskID == self.currentLoadingTaskID else { return }
			
			self.pdfController = SimplePDFViewController() <- {
				$0.delegate = self
				$0.backgroundColor = .white // some maps have a transparent background and black elements, so they need a bright background
				$0.page = page // should be set after the background color (technically a race condition otherwise)
				$0.overlayView.alpha = self.markerAlpha
				$0.overlayView.backgroundColor = .darkOverlay
				$0.additionalSafeAreaInsets.bottom += self.pullableView.minHeight
					+ 8 // for symmetry
			}
			self.updateSectors()
			self.updateMarkers()
		}
		
		page.catch { error in
			guard taskID == self.currentLoadingTaskID else { return }
			
			error.printDetails(context: "Error while loading PDF!")
			self.activityIndicator.stopAnimating()
			self.fallbackLabel.text = Localization.couldNotLoad
		}
	}
	
	private func updateSectors() {
		let pdfController = self.pdfController!
		pdfController.view.layoutIfNeeded()
		if let sectorFrame = map?.sectorFrame.map(CGRect.init) {
			pdfController.overlayView.addSubview(sectorView)
			sectorView.frame = sectorFrame * pdfController.overlayView.bounds.size
		} else {
			sectorView.removeFromSuperview()
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
			marker.isStatusShown = visibleStatuses.contains(marker.issue.status.simplified)
		}
	}
	
	func showDetails(for issue: Issue) {
		let viewController = issue.isRegistered
			? storyboard!.instantiate(ViewIssueViewController.self)! <- { $0.issue = issue }
			: storyboard!.instantiate(EditIssueViewController.self)! <- { $0.present(issue) }
		
		let navController = UINavigationController(rootViewController: viewController)
			<- { $0.modalPresentationStyle = .formSheet }
		
		present(navController, animated: true)
		navController.presentationController?.delegate = self
	}
}

extension MapViewController: SimplePDFViewControllerDelegate {
	func pdfZoomed(to scale: CGFloat) {
		markers.forEach { $0.zoomScale = scale }
		sectorViews.forEach { $0.zoomScale = scale }
	}
	
	func pdfFinishedLoading() {
		activityIndicator.stopAnimating()
		fallbackLabel.text = nil
		
		markerAlpha = 1
	}
}

extension MapViewController: StatusFilterViewControllerDelegate {
	func statusFilterChanged(to newValue: Set<Issue.Status.Simplified>) {
		visibleStatuses = newValue
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

extension MapViewController: SectorViewDelegate {
	func zoomMap(to sectorView: SectorView) {
		let pdfController = self.pdfController!
		
		let rect = pdfController.overlayView.convert(sectorView.bounds, from: sectorView)
		pdfController.scrollView.zoom(to: rect, animated: true)
	}
}

extension MapViewController: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		didReturnFromModal()
	}
	
	func didReturnFromModal() {
		guard let map = holder as? Map else { return }
		
		cancelAddingIssue() // done (if started)
		
		issues = Repository.read(map.sortedIssues.fetchAll)
		updateMarkers()
		issueListController.update()
		
		let mainController = splitViewController as! MainViewController
		for viewController in mainController.masterNav.viewControllers {
			(viewController as? MapListViewController)?.reload(map)
		}
	}
}

extension Issue {
	static let allStatuses = Set(Issue.Status.Simplified.allCases)
}
