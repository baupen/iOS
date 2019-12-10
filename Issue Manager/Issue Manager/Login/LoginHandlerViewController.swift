// Created by Julian Dunskus

import UIKit

class LoginHandlerViewController: UIViewController {
	private typealias Localization = L10n.Login
	
	var isLoggingIn = false
	
	func logIn(username: String, password: String) {
		isLoggingIn = true
		let result = Client.shared.logIn(as: username, password: password).on(.main)
		result.always {
			self.isLoggingIn = false
		}
		
		result.then {
			self.showSiteList()
		}
		
		result.catch { error in
			error.printDetails(context: "Login Failed!")
			self.handle(error, username: username, password: password)
		}
	}
	
	func handle(_ error: Error, username: String, password: String) {
		switch error {
		case RequestError.apiError(let meta) where meta.error == .unknownUsername:
			fallthrough
		case RequestError.invalidUsername:
			showUnknownUsernameAlert(username: username)
		case RequestError.apiError(let meta) where meta.error == .wrongPassword:
			showWrongPasswordAlert(username: username)
		case RequestError.communicationError: // likely connection failure
			let wasAttemptValid = attemptLocalLogin(username: username, password: password)
			if !wasAttemptValid {
				showAlert(
					titled: L10n.Alert.ConnectionIssues.title,
					message: L10n.Alert.ConnectionIssues.message
				)
			}
		case RequestError.outdatedClient(let client, let server):
			print("Outdated client! client: \(client), server: \(server)")
			showAlert(
				titled: L10n.Alert.OutdatedClient.title,
				message: L10n.Alert.OutdatedClient.message
			)
		default:
			showAlert(
				titled: Localization.Alert.LoginError.title,
				message: Localization.Alert.LoginError.message
			) {
				self.attemptLocalLogin(username: username, password: password)
			}
		}
	}
	
	/// - returns: whether or not the attempt was valid—if `false`, the user shouldn't know any attempt occurred.
	@discardableResult func attemptLocalLogin(username: String, password: String) -> Bool {
		guard
			let localUser = Client.shared.localUser,
			username == localUser.localUsername
			else { return false }
		
		guard password.sha256() == localUser.passwordHash else {
			showWrongPasswordAlert(username: username)
			return true
		}
		
		print("Logged in locally!")
		showSiteList()
		return true
	}
	
	func showUnknownUsernameAlert(username: String) {
		showAlert(
			titled: Localization.Alert.WrongUsername.title,
			message: Localization.Alert.WrongUsername.message(username)
		)
	}
	
	func showWrongPasswordAlert(username: String) {
		showAlert(
			titled: Localization.Alert.WrongPassword.title,
			message: Localization.Alert.WrongPassword.message(username)
		)
	}
	
	func showSiteList(userInitiated: Bool = true) {
		Client.shared.localUser?.hasLoggedOut = false
		
		let siteList = storyboard!.instantiate(SiteListViewController.self)!
		if !userInitiated {
			siteList.needsRefresh = true
		}
		present(siteList, animated: userInitiated)
	}
}
