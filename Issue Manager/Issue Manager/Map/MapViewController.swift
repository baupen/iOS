// Created by Julian Dunskus

import UIKit
import SimplePDFKit
import PullToExpand

class MapViewController: UIViewController, LoadedViewController {
	typealias Localization = L10n.Map
	
	static let storyboardID = "Map"
	
	@IBOutlet var fallbackLabel: UILabel!
	@IBOutlet var pdfContainerView: UIView!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var pullableView: PullableView!
	@IBOutlet var blurHeightConstraint: NSLayoutConstraint!
	@IBOutlet var listHeightConstraint: NSLayoutConstraint!
	
	var issueListController: IssueListViewController!
	
	var pdfController: SimplePDFViewController? {
		didSet {
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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateBarButtonItem()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let safeArea = UIEdgeInsetsInsetRect(view.bounds, view.safeAreaInsets)
		let allowedHeight = safeArea.height * 2/3
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
		// called in the beginning when the list controller is embedded
		issueListController = (segue.destination as! IssueListViewController)
		issueListController.pullableView = pullableView
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
		
		navigationItem.title = holder?.name ?? Localization.title
		
		if let map = holder as? Map, let filename = map.filename {
			let url = Map.cacheURL(filename: filename)
			asyncLoadPDF(at: url)
			
			pullableView.isHidden = false
			issueListController.map = map
		} else {
			pdfController = nil
			if let holder = holder {
				fallbackLabel.text = Localization.noPdf(holder.name)
			} else {
				fallbackLabel.text = Localization.noMapSelected
			}
			pullableView.isHidden = true
		}
	}
	
	func asyncLoadPDF(at url: URL) {
		let page = Future
			.init(asyncOn: .global()) { try PDFDocument(at: url).page(0) }
			.on(.main)
		
		pdfController = nil
		fallbackLabel.text = Localization.pdfLoading
		activityIndicator.startAnimating()
		page.always(activityIndicator.stopAnimating)
		
		page.then { page in
			self.pdfController = SimplePDFViewController() <- {
				$0.page = page
			}
		}
		
		page.catch { error in
			print("Error while loading PDF!", error.localizedDescription)
			dump(error)
			self.fallbackLabel.text = Localization.couldNotLoad
		}
	}
}
