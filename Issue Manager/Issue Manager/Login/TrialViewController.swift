// Created by Julian Dunskus

import UIKit

class TrialViewController: UIViewController {
	fileprivate typealias Localization = L10n.Trial
	
	@IBOutlet var backgroundView: UIVisualEffectView!
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
	
	var trialUser: TrialUser? {
		didSet {
			let hasUser = trialUser != nil
			if !hasUser {
				givenNameField.becomeFirstResponder()
			}
			textFieldView.isShown = !hasUser
			labelView.isShown = hasUser
			
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
		return PresentAnimator()
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return DismissAnimator()
	}
}

fileprivate class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.25
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {}
	
	fileprivate func animate(using transitionContext: UIViewControllerContextTransitioning, _ animations: @escaping () -> Void) {
		UIView.animate(
			withDuration: transitionDuration(using: transitionContext),
			delay: 0,
			options: transitionContext.isInteractive ? .curveLinear : .curveEaseInOut,
			animations: animations,
			completion: { _ in transitionContext.completeTransition(!transitionContext.transitionWasCancelled) }
		)
	}
}

fileprivate class PresentAnimator: TransitionAnimator {
	override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let trialController = transitionContext.viewController(forKey: .to) as! TrialViewController
		trialController.view.layoutIfNeeded()
		
		transitionContext.containerView.insertSubview(trialController.view, at: 0)
		
		let offset = trialController.view.bounds.height
		let pulledView = trialController.loginWindowView!
		let finalFrame = pulledView.frame
		pulledView.frame = pulledView.frame.offsetBy(dx: 0, dy: offset)
		
		let effect = trialController.backgroundView.effect!
		trialController.backgroundView.effect = nil
		
		animate(using: transitionContext) {
			pulledView.frame = finalFrame
			trialController.backgroundView.effect = effect
		}
	}
}

fileprivate class DismissAnimator: TransitionAnimator {
	override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let trialController = transitionContext.viewController(forKey: .from) as! TrialViewController
		
		let offset = trialController.view.bounds.height
		let pulledView = trialController.loginWindowView!
		let finalFrame = pulledView.frame.offsetBy(dx: 0, dy: offset)
		
		animate(using: transitionContext) {
			pulledView.frame = finalFrame
			trialController.backgroundView.effect = nil
		}
	}
}
