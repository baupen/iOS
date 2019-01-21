// Created by Julian Dunskus

import UIKit

class TrialViewController: LoginHandlerViewController {
	fileprivate typealias Localization = L10n.Trial
	
	@IBOutlet var loginWindowView: UIView!
	
	@IBOutlet var textFieldView: UIView!
	@IBOutlet var givenNameField: UITextField!
	@IBOutlet var familyNameField: UITextField!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	
	@IBOutlet var labelView: UIView!
	@IBOutlet var usernameLabel: UILabel!
	@IBOutlet var passwordLabel: UILabel!
	
	@IBOutlet var loginButton: UIButton!
	
	@IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
		givenNameField.resignFirstResponder()
		familyNameField.resignFirstResponder()
	}
	
	@IBAction func confirm() {
		if let trialUser = trialUser {
			logIn(username: trialUser.username, password: trialUser.password)
		} else {
			requestTrial()
		}
	}
	
	// unwind segue
	// TODO: find out if this successfully overwrites LoginViewController's unwind segue
	@IBAction func logOut(_ segue: UIStoryboardSegue) {}
	
	/// - note: only ever change this from the main queue
	var isRequestingTrial = false {
		didSet {
			loginButton.isEnabled = !isRequestingTrial
			givenNameField.isEnabled = !isRequestingTrial
			familyNameField.isEnabled = !isRequestingTrial
			textFieldView.alpha = isRequestingTrial ? 0.5 : 1
			
			if isRequestingTrial {
				activityIndicator.startAnimating()
			} else {
				activityIndicator.stopAnimating()
			}
		}
	}
	
	/// - note: only ever change this from the main queue
	override var isLoggingIn: Bool {
		didSet {
			labelView.alpha = isLoggingIn ? 0.5 : 1
			
			if isLoggingIn {
				activityIndicator.startAnimating()
			} else {
				activityIndicator.stopAnimating()
			}
		}
	}
	
	var trialUser: TrialUser? {
		didSet {
			let hasUser = trialUser != nil
			textFieldView.isShown = !hasUser
			labelView.isShown = hasUser
			
			if let trialUser = trialUser {
				usernameLabel.text = trialUser.username
				passwordLabel.text = trialUser.password
			}
			
			loginButton.setTitle(hasUser ? Localization.logIn : Localization.createAccount, for: .normal)
		}
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		transitioningDelegate = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		givenNameField.delegate = self
		familyNameField.delegate = self
		
		trialUser = defaults.trialUser
	}
	
	func requestTrial() {
		let givenName = givenNameField.text!.nonEmptyOptional
		let familyName = familyNameField.text!.nonEmptyOptional
		
		isRequestingTrial = true
		let result = Client.shared.createTrialAccount(proposedGivenName: givenName, proposedFamilyName: familyName).on(.main)
		result.always {
			self.isRequestingTrial = false
		}
		
		result.then { trialUser in
			print("Created trial user:", trialUser)
			self.trialUser = trialUser
			defaults.trialUser = trialUser
		}
		
		result.catch { error in
			print("Trial creation failed!", error.localizedFailureReason)
			dump(error)
			self.showAlert(for: error)
		}
	}
	
	func showAlert(for error: Error) {
		switch error {
		case RequestError.outdatedClient(let client, let server):
			print("Outdated client! client: \(client), server: \(server)")
			showAlert(
				titled: L10n.Alert.OutdatedClient.title,
				message: L10n.Alert.OutdatedClient.message
			)
		default:
			// FIXME: change messages
			showAlert(
				titled: L10n.Login.Alert.LoginError.title,
				message: L10n.Login.Alert.LoginError.message
			)
		}
	}
	
	func showSiteList(animated: Bool = true) {
		let controller = storyboard!.instantiate(SiteListViewController.self)!
		controller.modalTransitionStyle = .flipHorizontal
		present(controller, animated: animated)
	}
}

extension TrialViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		switch textField {
		case givenNameField:
			familyNameField.becomeFirstResponder()
		case familyNameField:
			familyNameField.resignFirstResponder()
			requestTrial()
		default:
			return true // default handling
		}
		return false // custom handling
	}
}

extension TrialViewController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return VerticalSlideTransitionAnimator(shouldMoveDown: false)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return VerticalSlideTransitionAnimator(shouldMoveDown: true)
	}
}

fileprivate class VerticalSlideTransitionAnimator: TransitionAnimator {
	let shouldMoveDown: Bool
	
	init(shouldMoveDown: Bool) {
		self.shouldMoveDown = shouldMoveDown
		
		super.init()
	}
	
	override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let fromView = transitionContext.viewController(forKey: .from)!.view!
		let toView = transitionContext.viewController(forKey: .to)!.view!
		
		transitionContext.containerView.addSubview(toView)
		let bounds = transitionContext.containerView.bounds
		let offset = bounds.height * (shouldMoveDown ? -1 : +1)
		
		toView.frame = bounds.offsetBy(dx: 0, dy: offset)
		
		animate(using: transitionContext) { 
			fromView.frame = bounds.offsetBy(dx: 0, dy: -offset)
			toView.frame = bounds
		}
	}
}
