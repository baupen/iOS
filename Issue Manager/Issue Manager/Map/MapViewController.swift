// Created by Julian Dunskus

import UIKit

class MapViewController: UIViewController, LoadedViewController {
	typealias Localization = L10n.Map
	
	static let storyboardID = "Map"
	
	@IBOutlet var testLabel: UILabel!
	
	var holder: MapHolder? {
		didSet {
			update()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	override func didMove(toParentViewController parent: UIViewController?) {
		guard parent != nil else { return }
		
		if parent is MasterNavigationController {
			navigationItem.leftBarButtonItem = nil
		} else if parent is DetailNavigationController {
			navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem
		} else {
			fatalError()
		}
	}
	
	func update() {
		guard isViewLoaded else { return }
		
		navigationItem.title = holder?.name ?? Localization.title
		
		if let holder = holder {
			testLabel.text = """
			Showing \(holder.name)!
			\(holder.filename ?? "<no file>")
			"""
		} else {
			testLabel.text = "<no holder>"
		}
	}
}
