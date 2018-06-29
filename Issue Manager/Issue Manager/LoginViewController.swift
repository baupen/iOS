// Created by Julian Dunskus

import UIKit

class LoginViewController: UIViewController {
	@IBOutlet var textFieldView: UIStackView!
	@IBOutlet var usernameField: UITextField!
	@IBOutlet var passwordField: UITextField!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	
	// unwind segue
	@IBAction func logOut(_ segue: UIStoryboardSegue) {
		passwordField.text = ""
	}
	
	var isLoggingIn = false {
		didSet {
			let isLoggingIn = self.isLoggingIn // capture
			DispatchQueue.main.async {
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
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		usernameField.delegate = self
		passwordField.delegate = self
		if let username = Client.shared.user?.username, !username.isEmpty {
			usernameField.text = Client.shared.user?.username
			passwordField.becomeFirstResponder()
		} else {
			usernameField.becomeFirstResponder()
		}
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	func logIn() {
		// TODO indicator?
		let username = usernameField.text!
		let password = passwordField.text!
		
		isLoggingIn = true
		let result = Client.shared.logIn(as: username, password: password)
		result.always {
			self.isLoggingIn = false
		}
		
		result.then {
			print("Logged in!")
			print(Client.shared.user!.authenticationToken)
			DispatchQueue.main.async(execute: self.showMainController)
		}
		
		result.catch { error in
			DispatchQueue.main.async {
				print("Login Failed!")
				print(error.localizedDescription)
				print(error)
				
				switch error as! RequestError {
				case RequestError.apiError(let meta) where meta.error == .unknownUsername:
					self.showUnknownUsernameAlert(username: username)
				case RequestError.apiError(let meta) where meta.error == .wrongPassword:
					self.showWrongPasswordAlert(username: username)
				case RequestError.communicationError(let error): // likely connection failure
					print("Request Error!", error)
					print(error.localizedDescription)
					print(error)
					
					self.attemptLocalLogin()
				default:
					let message = """
					Beim einloggen ist ein Fehler aufgetreten!
					
					\(error.localizedDescription)
					
					Sie werden falls möglich lokal eingeloggt.
					"""
					self.showAlert(titled: "Fehler!", message: message) {
						self.attemptLocalLogin(showingAlerts: false)
					}
				}
			}
		}
	}
	
	/// - returns: whether or not 
	func attemptLocalLogin(showingAlerts: Bool = true) {
		let username = usernameField.text!
		let password = passwordField.text!
		guard let user = Client.shared.user else {
			if showingAlerts {
				showAlert(titled: "Verbindungsproblem", message: "Es konnte keine Verbindung zum Dienst aufgebaut werden.")
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
		showMainController()
	}
	
	func showUnknownUsernameAlert(username: String) {
		showAlert(titled: "Falscher Benutzername!", message: "Es gibt keinen Benutzer namens \"\(username)\".")
	}
	
	func showWrongPasswordAlert(username: String) {
		showAlert(titled: "Falsches Passwort!", message: "Das ist nicht das richtige Passwort für den Benutzer \"\(username)\".")
	}
	
	func showMainController() {
		let mainController = storyboard!.instantiate(MainViewController.self)!
		mainController.modalTransitionStyle = .flipHorizontal
		present(mainController, animated: true)
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

//@IBDesignable
class LoginWindowView: UIView {
	// required for live preview
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		setUp()
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		
		setUp()
	}
	
	func setUp() {
		layer.cornerRadius = 16
		
		layer.shadowOpacity = 0.25
		layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		layer.shadowOffset = CGSize(width: 0, height: 16)
		layer.shadowRadius = 32
	}
}
