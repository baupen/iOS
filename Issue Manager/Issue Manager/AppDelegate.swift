// Created by Julian Dunskus

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
	var window: UIWindow?
	
	let reachability = Reachability() <- {
		$0?.whenReachable = { _ in
			print("Reachable again! Trying to clear backlog...")
			Client.shared.tryToClearBacklog()
		}
	}
	
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		registerDefaults()
		
		window!.tintColor = .main
		
		// disables state restoration animations
		window!.isHidden = false
		
		return true
	}
	
	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		true
	}
	
	// FIXME: deprecated in iOS 13
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		Client.shared.localUser != nil && !defaults.isInClientMode
	}
}
