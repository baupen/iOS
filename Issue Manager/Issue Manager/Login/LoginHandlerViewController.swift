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
			print("Logged in as", Client.shared.localUser!.user.authenticationToken)
			self.showSiteList()
		}
		
		result.catch { error in
			print("Login Failed!", error.localizedFailureReason)
			dump(error)
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
			attemptLocalLogin(username: username, password: password, showingAlerts: true)
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
				self.attemptLocalLogin(username: username, password: password, showingAlerts: false)
			}
		}
	}
	
	func attemptLocalLogin(username: String, password: String, showingAlerts: Bool) {
		guard let localUser = Client.shared.localUser else {
			if showingAlerts {
				showAlert(
					titled: L10n.Alert.ConnectionIssues.title,
					message: L10n.Alert.ConnectionIssues.message
				)
			}
			return
		}
		
		guard username == localUser.localUsername else {
			if showingAlerts {
				showUnknownUsernameAlert(username: username)
			}
			return
		}
		guard password.sha256() == localUser.passwordHash else {
			if showingAlerts {
				showWrongPasswordAlert(username: username)
			}
			return
		}
		
		print("Logged in locally!")
		showSiteList()
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
	
	func showSiteList() {
		let controller = storyboard!.instantiate(SiteListViewController.self)!
		controller.modalTransitionStyle = .flipHorizontal
		present(controller, animated: true)
	}
}
