// Created by Julian Dunskus

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
	private static let wipeVersion = 1
	
	var window: UIWindow?
	
	let reachability = Reachability() <- {
		$0?.whenReachable = { _ in
			print("Reachable again! Trying to push any changes that weren't pushed earlier...")
			try? Client.shared.pushLocalChanges().await()
		}
	}
	
	private func wipeAllData() {
		print("wiping all data!")
		
		defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
		defaults.lastWipeVersion = Self.wipeVersion
		wipeDownloadedFiles()
		DatabaseDataStore.wipeData()
		
		let loginController = window!.rootViewController!
		loginController.dismiss(animated: true) {
			loginController.showAlert(
				titled: L10n.Alert.Wiped.title,
				message: L10n.Alert.Wiped.message,
				okMessage: L10n.Alert.Wiped.quit
			) { exit(0) }
		}
	}

	func application(
		_ app: UIApplication,
		willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		registerDefaults()
		
		window!.tintColor = .main
		
		// disables state restoration animations
		window!.isHidden = false
		
		if defaults.lastWipeVersion < Self.wipeVersion {
			wipeAllData()
		}
		
		return true
	}
	
	func application(
		_ app: UIApplication,
		open url: URL,
		options: [UIApplication.OpenURLOptionsKey: Any] = [:]
	) -> Bool {
		guard
			let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
			components.scheme == "mangelio"
			else { return false }
		
		switch components.host {
		case "login":
			guard
				let queryItems = components.queryItems,
				let payload = queryItems.first(where: { $0.name == "payload" })?.value,
				let rawPayload = Data(base64Encoded: payload),
				let loginInfo = try? JSONDecoder().decode(LoginInfo.self, from: rawPayload)
			else {
				print("malformed custom url: \(url)")
				return false
			}
			
			let loginController = window!.rootViewController as! LoginViewController
			loginController.logIn(with: loginInfo)
			
			return true
		case "wipe":
			wipeAllData()
			return true
		default:
			print("unrecognized custom url host in \(url)")
			return false
		}
	}
	
	func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool { true }
	
	func application(_ app: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
		Client.shared.localUser != nil && !defaults.isInClientMode
	}
}
