// Created by Julian Dunskus

import UIKit

final class LoginViewController: LoginHandlerViewController {
	fileprivate typealias Localization = L10n.Login
	
	@IBOutlet var textFieldView: UIView!
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
	override var isLoggingIn: Bool {
		didSet {
			usernameField.isEnabled = !isLoggingIn
			passwordField.isEnabled = !isLoggingIn
			textFieldView.alpha = isLoggingIn ? 0.5 : 1
			
			if isLoggingIn {
				activityIndicator.startAnimating()
			} else {
				activityIndicator.stopAnimating()
			}
		}
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		usernameField.delegate = self
		passwordField.delegate = self
		
		if let username = Client.shared.localUser?.localUsername, !username.isEmpty {
			usernameField.text = username
			
			if defaults.stayLoggedIn {
				DispatchQueue.main.async {
					self.showSiteList(userInitiated: false)
				}
			} else {
				passwordField.becomeFirstResponder()
			}
		} else {
			usernameField.becomeFirstResponder()
		}
		
		stayLoggedInSwitch.isOn = defaults.stayLoggedIn
	}
	
	func logIn() {
		logIn(username: usernameField.text!, password: passwordField.text!)
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
