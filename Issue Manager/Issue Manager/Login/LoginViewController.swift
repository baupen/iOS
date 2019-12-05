// Created by Julian Dunskus

import UIKit

final class LoginViewController: LoginHandlerViewController {
	fileprivate typealias Localization = L10n.Login
	
	@IBOutlet private var textFieldView: UIView!
	@IBOutlet private var usernameField: UITextField!
	@IBOutlet private var passwordField: UITextField!
	@IBOutlet private var activityIndicator: UIActivityIndicatorView!
	@IBOutlet private var stayLoggedInSwitch: UISwitch!
	
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
		Client.shared.localUser?.hasLoggedOut = true
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
		.lightContent
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		usernameField.delegate = self
		passwordField.delegate = self
		
		stayLoggedInSwitch.isOn = defaults.stayLoggedIn
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let localUser = Client.shared.localUser, !localUser.localUsername.isEmpty {
			usernameField.text = localUser.localUsername
			
			if defaults.stayLoggedIn, !localUser.hasLoggedOut {
				showSiteList(userInitiated: false)
			} else {
				passwordField.becomeFirstResponder()
			}
		} else {
			usernameField.becomeFirstResponder()
		}
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
