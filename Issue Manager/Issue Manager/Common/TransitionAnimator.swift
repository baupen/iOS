// Created by Julian Dunskus

import UIKit

class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.25
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {}
	
	// need this explicitly so you can use trailing closures for it.
	func animate(using transitionContext: UIViewControllerContextTransitioning, animations: @escaping () -> Void) {
		animate(using: transitionContext, animations: animations, completion: nil)
	}
	
	func animate(using transitionContext: UIViewControllerContextTransitioning, animations: @escaping () -> Void, completion: ((_ cancelled: Bool) -> Void)?) {
		UIView.animate(
			withDuration: transitionDuration(using: transitionContext),
			delay: 0,
			options: transitionContext.isInteractive ? .curveLinear : .curveEaseInOut,
			animations: animations,
			completion: { _ in
				completion?(transitionContext.transitionWasCancelled)
				transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
			}
		)
	}
}
