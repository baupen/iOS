// Created by Julian Dunskus

import UIKit
import UserDefault

final class LoginViewController: UIViewController {
	private typealias Localization = L10n.Login
	
	var isLoggingIn = false
	
	// unwind segue
	@IBAction func logOut(_ segue: UIStoryboardSegue) {
		Client.shared.localUser = nil
	}
	
	private var shouldRestoreState = true
	
	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard shouldRestoreState else { return }
		shouldRestoreState = false
		
		guard Client.shared.isLoggedIn, presentedViewController == nil else { return }
		
		showSiteList(userInitiated: false)
	}
	
	func logIn(with info: LoginInfo) {
		shouldRestoreState = false
		
		// dismiss any presented view controllers
		dismiss(animated: false) // don't have to animate since we're not visible until done anyway
		
		Client.shared.logIn(with: info)
			.on(.main)
			.catch(showAlert(for:))
			.then { self.showSiteList() }
	}
	
	func showAlert(for error: Error) {
		switch error {
		case RequestError.communicationError: // likely connection failure
			showAlert(
				titled: L10n.Alert.ConnectionIssues.title,
				message: L10n.Alert.ConnectionIssues.message
			)
		default:
			print("login error!")
			dump(error)
			let errorDesc = "" <- {
				dump(error, to: &$0)
			}
			showAlert(
				titled: Localization.Alert.LoginError.title,
				message: Localization.Alert.LoginError.message
					+ "\n\n" + errorDesc
			)
		}
	}
	
	func showSiteList(userInitiated: Bool = true) {
		let siteList = storyboard!.instantiate(SiteListViewController.self)!
		if !userInitiated {
			siteList.needsRefresh = true
		}
		present(siteList, animated: userInitiated)
	}
}

private let https = "https://"
private extension URL {
	func trimmingHTTPS() -> String {
		let string = absoluteString
		return string.hasPrefix(https)
			? String(string.dropFirst(https.count))
			: string
	}
	
	static func prependingHTTPSIfMissing(to raw: String) -> URL? {
		URL(string: URLComponents(string: raw)?.scheme != nil ? raw : https + raw)
	}
}
