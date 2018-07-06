// Created by Julian Dunskus

import UIKit

class LoginViewController: UIViewController {
	fileprivate typealias Localization = L10n.Login
	
	@IBOutlet var textFieldView: UIStackView!
	@IBOutlet var usernameField: UITextField!
	@IBOutlet var passwordField: UITextField!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var stayLoggedInSwitch: UISwitch!
	
	@IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
		usernameField.resignFirstResponder()
		passwordField.resignFirstResponder()
	}
	
	@IBAction func stayLoggedInSwitched() {
		defaults.stayLoggedIn = stayLoggedInSwitch.isOn
	}
	
	// unwind segue
	@IBAction func logOut(_ segue: UIStoryboardSegue) {
		passwordField.text = ""
	}
	
	/// - note: only ever change this from the main queue
	var isLoggingIn = false {
		didSet {
			let isLoggingIn = self.isLoggingIn // capture
			
			self.usernameField.isEnabled = !isLoggingIn
			self.passwordField.isEnabled = !isLoggingIn
			self.textFieldView.alpha = isLoggingIn ? 0.5 : 1
			
			if isLoggingIn {
				self.activityIndicator.startAnimating()
			} else {
				self.activityIndicator.stopAnimating()
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		usernameField.delegate = self
		passwordField.delegate = self
		
		if let username = Client.shared.user?.username, !username.isEmpty {
			usernameField.text = Client.shared.user?.username
			
			if !defaults.stayLoggedIn {
				passwordField.becomeFirstResponder()
			}
		} else {
			usernameField.becomeFirstResponder()
		}
		
		stayLoggedInSwitch.isOn = defaults.stayLoggedIn
		
		if defaults.stayLoggedIn, Client.shared.user != nil {
			// not right now but asap
			DispatchQueue.main.async {
				self.showBuildingList(animated: false)
			}
		}
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	func logIn() {
		let username = usernameField.text!
		let password = passwordField.text!
		
		isLoggingIn = true
		let result = Client.shared.logIn(as: username, password: password).on(.main)
		result.always {
			self.isLoggingIn = false
		}
		
		result.then {
			print("Logged in as", Client.shared.user!.authenticationToken)
			self.showBuildingList()
		}
		
		result.catch { error in
			print("Login Failed!", error.localizedDescription)
			dump(error)
			
			switch error as! RequestError {
			case RequestError.apiError(let meta) where meta.error == .unknownUsername:
				self.showUnknownUsernameAlert(username: username)
			case RequestError.apiError(let meta) where meta.error == .wrongPassword:
				self.showWrongPasswordAlert(username: username)
			case RequestError.communicationError: // likely connection failure
				self.attemptLocalLogin()
			default:
				self.showAlert(
					titled: Localization.Alert.LoginError.title,
					message: Localization.Alert.LoginError.message
				) {
					self.attemptLocalLogin(showingAlerts: false)
				}
			}
		}
	}
	
	func attemptLocalLogin(showingAlerts: Bool = true) {
		let username = usernameField.text!
		let password = passwordField.text!
		guard let user = Client.shared.user else {
			if showingAlerts {
				showAlert(titled: L10n.Alert.ConnectionIssues.title,
						  message: L10n.Alert.ConnectionIssues.message)
			}
			return
		}
		
		guard username == user.username else {
			if showingAlerts {
				showUnknownUsernameAlert(username: username)
			}
			return
		}
		guard password.sha256() == user.passwordHash else {
			if showingAlerts {
				showWrongPasswordAlert(username: username)
			}
			return
		}
		
		print("Logged in locally!")
		showBuildingList()
	}
	
	func showUnknownUsernameAlert(username: String) {
		showAlert(titled: Localization.Alert.WrongUsername.title,
				  message: Localization.Alert.WrongUsername.message(username))
	}
	
	func showWrongPasswordAlert(username: String) {
		showAlert(titled: Localization.Alert.WrongPassword.title,
				  message: Localization.Alert.WrongPassword.message(username))
	}
	
	func showBuildingList(animated: Bool = true) {
		let controller = storyboard!.instantiate(BuildingListViewController.self)!
		controller.modalTransitionStyle = .flipHorizontal
		present(controller, animated: animated)
	}
}

extension LoginViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		switch textField {
		case usernameField:
			passwordField.becomeFirstResponder()
		case passwordField:
			passwordField.resignFirstResponder()
			logIn()
		default:
			return true // default handling
		}
		return false // custom handling
	}
}
