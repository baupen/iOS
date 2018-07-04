// Created by Julian Dunskus

import UIKit

class MainViewController: UISplitViewController, LoadedViewController {
	static let storyboardID = "Main"
	
	var building: Building! {
		didSet {
			let mapList = masterNav!.topViewController as! MapListViewController
			mapList.source = building
		}
	}
	
	var masterNav: MasterNavigationController? {
		return viewControllers.first! as? MasterNavigationController
	}
	
	var detailNav: DetailNavigationController? {
		return viewControllers.last! as? DetailNavigationController
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		preferredDisplayMode = .allVisible
	}
}

class MasterNavigationController: UINavigationController {
	override func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController? {
		if let detailNav = topViewController as? DetailNavigationController {
			popViewController(animated: false)
			return detailNav
		} else if let mapController = topViewController as? MapViewController {
			popViewController(animated: false)
			return DetailNavigationController(rootViewController: mapController)
		} else {
			return nil
		}
	}
	
	override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
		let detailNav = secondaryViewController as! DetailNavigationController
		let mapController = detailNav.topViewController as! MapViewController
		if mapController.map?.filename != nil {
			pushViewController(mapController, animated: false)
		}
	}
}

class DetailNavigationController: UINavigationController {}
