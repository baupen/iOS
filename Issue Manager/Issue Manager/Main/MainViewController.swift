// Created by Julian Dunskus

import UIKit

class MainViewController: UISplitViewController, LoadedViewController {
	static let storyboardID = "Main"
	
	var building: Building! {
		didSet {
			let mapList = masterNav.topViewController as! MapListViewController
			mapList.holder = building
		}
	}
	
	var masterNav: MasterNavigationController!
	var detailNav: DetailNavigationController!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		preferredDisplayMode = .allVisible
		
		masterNav = (viewControllers.first as! MasterNavigationController)
		detailNav = (viewControllers.last as! DetailNavigationController)
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		
		coder.encode(building.id, forKey: "buildingID")
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		// no way to gracefully fail from here; may as well crash if something goes wrong
		let buildingID = ID<Building>(coder.decodeObject(forKey: "buildingID") as! UUID)
		building = Client.shared.storage.buildings[buildingID]!
		
		let mapList = masterNav.topViewController as! MapListViewController
		mapList.refreshManually()
	}
}

class MasterNavigationController: UINavigationController {
	override var title: String? {
		get { return topViewController!.navigationItem.title }
		set {} // dummy
	}
	
	override func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController? {
		assert(!(topViewController is DetailNavigationController))
		let mainController = splitViewController as! MainViewController
		let detailNav = mainController.detailNav!
		
		let mapController = topViewController as? MapViewController
			?? storyboard!.instantiate()!
		
		detailNav.pushViewController(mapController, animated: false) // auto-pops from self
		viewControllers = viewControllers // update own controllers in case top was popped off
		mapController.didMove(toParentViewController: detailNav)
		
		return detailNav
	}
	
	override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
		let detailNav = secondaryViewController as! DetailNavigationController
		
		let mapController = detailNav.mapController
		detailNav.viewControllers = [] // can't pop root view controller explicitly
		mapController.didMove(toParentViewController: nil)
		
		if mapController.holder is Map {
			// worth keeping around
			pushViewController(mapController, animated: true)
			mapController.didMove(toParentViewController: self)
		}
	}
}

class DetailNavigationController: UINavigationController, LoadedViewController {
	static let storyboardID = "Detail"
	
	var mapController: MapViewController {
		return topViewController as! MapViewController
	}
}
