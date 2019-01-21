// Created by Julian Dunskus

import UIKit

class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.25
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {}
	
	func animate(using transitionContext: UIViewControllerContextTransitioning, _ animations: @escaping () -> Void) {
		UIView.animate(
			withDuration: transitionDuration(using: transitionContext),
			delay: 0,
			options: transitionContext.isInteractive ? .curveLinear : .curveEaseInOut,
			animations: animations,
			completion: { _ in transitionContext.completeTransition(!transitionContext.transitionWasCancelled) }
		)
	}
}
