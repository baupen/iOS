// Created by Julian Dunskus

import UIKit
import UserDefault
import HandyOperators
import SwiftUI

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
	static let shared = UIApplication.shared.delegate as! AppDelegate
	
	var window: UIWindow?
	
	func application(
		_ app: UIApplication,
		willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		#if DEBUG
		if ProcessInfo.processInfo.environment["RUNNING_TESTS"] == "1" {
			// hijack actual app content
			window!.rootViewController = UIViewController()
			return true
		}
		#endif
		
		window!.tintColor = .main
		
		// disables state restoration animations
		window!.isHidden = false
		
		wipeIfNecessary()
		
		Issue.moveLegacyFiles()
		
		ReachabilityTracker.shared.reachabilityChanged = { [syncManager] old, new in
			// check for transition from to reachable state (perhaps we switched from cellular to wifi—we still want to reattempt then)
			guard new.isReachable else { return }
			
			print("Reachable again! Trying to push any changes that weren't pushed earlier...")
			Task {
				try await syncManager.pushLocalChanges()
			}
		}
		
		return true
	}
	
	func application(
		_ app: UIApplication,
		open url: URL,
		options: [UIApplication.OpenURLOptionsKey: Any] = [:]
	) -> Bool {
		guard let link = DeepLink(from: url) else { return false }
		
		switch link {
		case .login(let loginInfo):
			let loginController = window!.rootViewController as! LoginViewController
			loginController.logIn(with: loginInfo)
		case .wipe:
			wipeAllDataThenExit()
		}
		
		return true
	}
	
	func wipeAllDataThenExit() {
		wipeAllData()
		
		dismissThenPerform {
			$0.showAlert(
				titled: L10n.Alert.Wiped.title,
				message: L10n.Alert.Wiped.message,
				okMessage: L10n.Alert.Wiped.quit
			) { exit(0) }
		}
	}
	
	func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool { true }
	
	func application(_ app: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
		client.localUser != nil && !Issue.isInClientMode
	}
	
	// MARK: - Wiping
	
	private static let wipeVersion = 2
	@UserDefault("lastWipeVersion")
	private static var lastWipeVersion: Int?
	
	private func wipeIfNecessary() {
		if Self.lastWipeVersion == nil {
			if DatabaseDataStore.databaseFileExists() {
				print("setting missing last wipe version to 1 because a database was present")
				Self.lastWipeVersion = 1
			} else {
				Self.lastWipeVersion = Self.wipeVersion
			}
		}
		
		if let lastWipe = Self.lastWipeVersion, lastWipe < Self.wipeVersion {
			print("last wipe version (\(lastWipe)) is older than current wipe version (\(Self.wipeVersion)).")
			wipeAllData()
			Self.lastWipeVersion = Self.wipeVersion
			
			dismissThenPerform {
				$0.showAlert(
					titled: L10n.Alert.UpgradeWiped.title,
					message: L10n.Alert.UpgradeWiped.message
				)
			}
		}
	}
	
	private func dismissThenPerform(_ block: @escaping (UIViewController) -> Void) {
		let loginController = window!.rootViewController!
		loginController.dismiss(animated: true) {
			block(loginController)
		}
	}
	
	private func wipeAllData() {
		print("wiping all data!")
		
		wipeDownloadedFiles()
		DatabaseDataStore.wipeData()
		client.wipeAllData()
	}
}

// singletons
private let sharedRepository = Repository(dataStore: try! .fromFile())
private let sharedClient = Client()
private let sharedSyncManager = SyncManager(client: sharedClient, repository: sharedRepository)

// poor man's dependency injection lol
// we're not testing view code, so it's fine to give that stuff access to the singleton

extension UIResponder {
	nonisolated var repository: Repository { sharedRepository }
	nonisolated var syncManager: SyncManager { sharedSyncManager }
	nonisolated var client: Client { sharedClient}
}

extension View {
	nonisolated var repository: Repository { sharedRepository }
	nonisolated var client: Client { sharedClient}
}
