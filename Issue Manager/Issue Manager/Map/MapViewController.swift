// Created by Julian Dunskus

import UIKit
import SimplePDFKit

class MapViewController: UIViewController, LoadedViewController {
	typealias Localization = L10n.Map
	
	static let storyboardID = "Map"
	
	@IBOutlet var fallbackLabel: UILabel!
	@IBOutlet var pdfContainerView: UIView!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	
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
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// called in the beginning when the controller is embedded
		pdfController = (segue.destination as! SimplePDFViewController)
	}
	
	override func didMove(toParentViewController parent: UIViewController?) {
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
		} else {
			pdfController = nil
			if holder != nil {
				fallbackLabel.text = Localization.noPdf
			} else {
				fallbackLabel.text = Localization.noMapSelected
			}
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
