// Created by Julian Dunskus

import UIKit
import UserDefault

final class LoginViewController: LoginHandlerViewController {
	fileprivate typealias Localization = L10n.Login
	
	@IBOutlet private var textFieldView: UIView!
	@IBOutlet private var usernameField: UITextField!
	@IBOutlet private var passwordField: UITextField!
	@IBOutlet private var websiteField: UITextField!
	@IBOutlet private var websiteFieldContainer: TextFieldContainer!
	@IBOutlet private var activityIndicator: UIActivityIndicatorView!
	@IBOutlet private var stayLoggedInSwitch: UISwitch!
	
	@IBAction func usernameConfirmed() {
		UIView.animate(withDuration: 0.25) {
			self.websiteFieldContainer.isHidden = false
		}
		updateWebsite()
	}
	
	@IBAction func backgroundTapped() {
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
	
	private var domainOverrides: [DomainOverride]? {
		didSet { updateWebsite() }
	}
	
	@UserDefault("login.lastFilledServerURL")
	private var lastFilledServerURL: URL?
	
	private var shouldRestoreState = true
	
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
	
	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		usernameField.delegate = self
		passwordField.delegate = self
		websiteField.delegate = self
		
		stayLoggedInSwitch.isOn = defaults.stayLoggedIn
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard shouldRestoreState else { return }
		shouldRestoreState = false
		
		if let localUser = Client.shared.localUser, !localUser.username.isEmpty {
			usernameField.text = localUser.username
			
			if defaults.stayLoggedIn, !localUser.hasLoggedOut {
				showSiteList(userInitiated: false)
			} else {
				passwordField.becomeFirstResponder()
			}
			
			websiteField.text = Client.shared.serverURL.trimmingHTTPS()
		} else {
			usernameField.becomeFirstResponder()
		}
		
		websiteFieldContainer.isHidden = usernameField.text?.isEmpty != false
		
		Client.shared.getDomainOverrides()
			.on(.main)
			.then { self.domainOverrides = $0 }
	}
	
	func updateWebsite() {
		guard
			let domainOverrides = domainOverrides,
			let input = Username(usernameField.text!)
			else { return }
		
		let override = domainOverrides.firstMatch(for: input)
		
		guard
			let serverURL = override?.serverURL
				?? .prependingHTTPSIfMissing(to: input.domain),
			serverURL != lastFilledServerURL
			else { return }
		
		lastFilledServerURL = serverURL
		websiteField.text = serverURL.trimmingHTTPS()
		usernameField.text = (override?.username ?? input).raw
	}
	
	func logIn() {
		guard let serverURL = URL.prependingHTTPSIfMissing(to: websiteField.text!) else {
			showAlert(
				titled: Localization.Alert.InvalidWebsite.title,
				message: Localization.Alert.InvalidWebsite.message
			)
			return
		}
		
		logIn(
			to: serverURL,
			as: usernameField.text!,
			password: passwordField.text!
		)
	}
	
	func deepLink(username: String, domain: String) {
		shouldRestoreState = false
		
		dismiss(animated: false) // don't have to animate since we're not visible until done anyway
		
		usernameField.text = username
		
		websiteField.text = domain
		lastFilledServerURL = .prependingHTTPSIfMissing(to: domain)
		websiteFieldContainer.isHidden = false
		
		passwordField.text = ""
		passwordField.becomeFirstResponder()
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

extension LoginViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		switch textField {
		case usernameField:
			passwordField.becomeFirstResponder()
		case passwordField:
			websiteField.becomeFirstResponder()
		case websiteField:
			websiteField.resignFirstResponder()
			logIn()
		default:
			return true // default handling
		}
		return false // custom handling
	}
}

extension URL: DefaultsValueConvertible {}
