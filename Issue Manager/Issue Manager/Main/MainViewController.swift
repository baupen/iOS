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
}

class MasterNavigationController: UINavigationController {
	override func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController? {
		assert(!(topViewController is DetailNavigationController))
		let mainController = splitViewController as! MainViewController
		let detailNav = mainController.detailNav!
		
		let mapController = topViewController as? MapViewController ?? storyboard!.instantiate()!
		detailNav.pushViewController(mapController, animated: false) // auto-pops from previous
		viewControllers = viewControllers // update
		mapController.didMove(toParentViewController: detailNav)
		return detailNav
	}
	
	override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
		let detailNav = secondaryViewController as! DetailNavigationController
		let mapController = detailNav.mapController
		
		if mapController.holder?.filename != nil {
			// worth keeping around
			pushViewController(mapController, animated: true) // auto-pops from previous
			mapController.didMove(toParentViewController: self) // apparently not called by pushViewController (i.e. only called once, with nil)
		}
	}
}

class DetailNavigationController: UINavigationController, LoadedViewController {
	static let storyboardID = "Detail"
	
	var mapController: MapViewController {
		return topViewController as! MapViewController
	}
}
