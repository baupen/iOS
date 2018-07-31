// Created by Julian Dunskus

import UIKit
import SimplePDFKit
import PullToExpand

final class MapViewController: UIViewController, LoadedViewController {
	typealias Localization = L10n.Map
	
	static let storyboardID = "Map"
	
	@IBOutlet var filterItem: UIBarButtonItem!
	@IBOutlet var addItem: UIBarButtonItem!
	
	@IBOutlet var fallbackLabel: UILabel!
	@IBOutlet var pdfContainerView: UIView!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var pullableView: PullableView!
	@IBOutlet var blurHeightConstraint: NSLayoutConstraint!
	@IBOutlet var listHeightConstraint: NSLayoutConstraint!
	@IBOutlet var issuePositioner: IssuePositioner!
	
	// the filter popover's done button and the add marker popover's cancel button link to this
	@IBAction func backToMap(_ segue: UIStoryboardSegue) {}
	
	// the issue popovers' done buttons link to this
	@IBAction func backToMapWithUpdates(_ segue: UIStoryboardSegue) {
		guard let map = holder as? Map else {
			assertionFailure("trying to update map controller without map")
			return
		}
		
		isPlacingIssue = false // done (if started)
		
		issues = map.allIssues()
		updateMarkers()
		issueListController.update()
		
		let mainController = splitViewController as! MainViewController
		for viewController in mainController.masterNav.viewControllers {
			(viewController as? MapListViewController)?.reload(map)
		}
	}
	
	@IBAction func beginAddingIssue() {
		pullableView.contract()
		
		issuePositioner.center = CGPoint(x: view.bounds.width, y: 0) // more or less where the add button is
		let center = view.bounds.size.asPoint / 2
		UIView.animate(withDuration: 0.25) {
			self.isPlacingIssue = true
			self.issuePositioner.center = center
		}
	}
	
	@IBAction func cancelAddingIssue() {
		UIView.animate(withDuration: 0.25) {
			self.isPlacingIssue = false
		}
	}
	
	var markers: [IssueMarker] = []
	var markerAlpha: CGFloat = 0.1 {
		didSet {
			pdfController?.overlayView.alpha = markerAlpha
		}
	}
	
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
			oldValue?.delegate = nil
			// embed/unembed controller
			guard pdfController != oldValue else { return }
			if let old = oldValue {
				old.willMove(toParentViewController: nil)
				old.view.removeFromSuperview()
				old.removeFromParentViewController()
			}
			if let new = pdfController {
				addChildViewController(new)
				pdfContainerView.addSubview(new.view)
				new.didMove(toParentViewController: self)
			}
		}
	}
	
	var holder: MapHolder? {
		didSet {
			update()
		}
	}
	
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
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let safeArea = UIEdgeInsetsInsetRect(view.bounds, view.safeAreaInsets)
		let allowedHeight = safeArea.height
		blurHeightConstraint.constant = allowedHeight + safeArea.height
		listHeightConstraint.constant = allowedHeight
		pullableView.maxHeight = allowedHeight
	}
	
	// not called at all in initial instantiation for some reason (hence the additional call in viewWillAppear)
	override func didMove(toParentViewController parent: UIViewController?) {
		super.didMove(toParentViewController: parent)
		
		updateBarButtonItem()
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
		case let editIssueNav as EditIssueNavigationController:
			let editController = editIssueNav.editIssueController
			editController.isCreating = true // otherwise we wouldn't be using a segue
			if isPlacingIssue {
				let position = Issue.Position(
					at: issuePositioner.relativePosition(in: pdfController!.overlayView),
					zoomScale: pdfController!.scrollView.zoomScale
				)
				editController.issue = Issue(at: isPlacingIssue ? position : nil, in: holder as! Map)
			} else {
				editController.issue = Issue(in: holder as! Map)
			}
		default:
			fatalError("unrecognized segue to \(segue.destination)")
		}
	}
	
	private func updateBarButtonItem() {
		guard parent != nil else { return }
		
		if parent is MasterNavigationController {
			navigationItem.leftBarButtonItem = nil
		} else if parent is DetailNavigationController {
			navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		} else {
			fatalError()
		}
	}
	
	func update() {
		guard isViewLoaded else { return }
		
		isPlacingIssue = false
		
		navigationItem.title = holder?.name ?? Localization.title
		
		let map = holder as? Map
		
		addItem.isEnabled = map != nil
		
		issues = map?.allIssues() ?? []
		
		issueListController.map = map
		pullableView.isHidden = map == nil
		
		if let filename = map?.filename {
			let url = Map.cacheURL(filename: filename)
			asyncLoadPDF(at: url)
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
	func asyncLoadPDF(at url: URL) {
		let page = Future
			.init(asyncOn: .global()) { try PDFDocument(at: url).page(0) }
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
				$0.page = page
				$0.overlayView.alpha = self.markerAlpha
				$0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.pullableView.minHeight, right: 0)
			}
			self.updateMarkers()
		}
		
		page.catch { error in
			guard taskID == self.currentLoadingTaskID else { return }
			
			print("Error while loading PDF!", error.localizedFailureReason)
			dump(error)
			self.activityIndicator.stopAnimating()
			self.fallbackLabel.text = Localization.couldNotLoad
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
			: storyboard!.instantiate(EditIssueViewController.self)! <- { $0.issue = issue }
		
		let navController = UINavigationController(rootViewController: viewController)
			<- { $0.modalPresentationStyle = .formSheet }
		
		present(navController, animated: true)
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
		let marker = markers.first { $0.issue === issue }!
		let size = pdfController.contentView.bounds.size * CGFloat(position.zoomScale)
		let centeredRect = CGRect(
			origin: marker.center - size / 2,
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

extension Issue {
	static let allStatuses = Set(Issue.Status.Simplified.allCases)
}
