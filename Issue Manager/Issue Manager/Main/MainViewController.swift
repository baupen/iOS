// Created by Julian Dunskus

import UIKit

class MainViewController: UISplitViewController, LoadedViewController {
	static let storyboardID = "Main"
	
	override var viewControllers: [UIViewController] {
		didSet {
			let mapList = masterNav!.topViewController as! MapListViewController
			mapList.updateShowMapButton()
		}
	}
	
	var building: Building! {
		didSet {
			let mapList = masterNav!.topViewController as! MapListViewController
			mapList.holder = building
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
		assert(!(topViewController is DetailNavigationController))
		if let mapController = topViewController as? MapViewController {
			popViewController(animated: false)
			return DetailNavigationController(rootViewController: mapController)
		} else {
			return storyboard!.instantiate(DetailNavigationController.self)!
		}
	}
	
	override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
		let detailNav = secondaryViewController as! DetailNavigationController
		let mapController = detailNav.topViewController as! MapViewController
		if mapController.holder?.filename != nil {
			// worth keeping around
			pushViewController(mapController, animated: true)
			mapController.didMove(toParentViewController: self) // apparently not called by pushViewController (i.e. only called once, with nil)
		}
	}
}

class DetailNavigationController: UINavigationController, LoadedViewController {
	static let storyboardID = "Detail"
}
