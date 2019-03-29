// Created by Julian Dunskus

import UIKit

final class LightboxViewController: UIViewController {
	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var aspectRatioConstraint: NSLayoutConstraint!
	
	var image: UIImage! {
		didSet { update() }
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		transitioningDelegate = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		UIView.animate(withDuration: animated ? 0.2 : 0) {
			self.isFullyShown = true
		}
	}
	
	private var isFullyShown = false {
		didSet { setNeedsStatusBarAppearanceUpdate() }
	}
	
	override var prefersStatusBarHidden: Bool { return isFullyShown }
	
	func update() {
		guard isViewLoaded, let image = image else { return }
		
		imageView.image = image
		aspectRatioConstraint.isActive = false
		aspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: image.size.width / image.size.height)
		aspectRatioConstraint.isActive = true
	}
	
	@IBAction func doubleTapped(_ tapRecognizer: UITapGestureRecognizer) {
		guard tapRecognizer.state == .recognized else { return }
		
		let position = tapRecognizer.location(in: imageView)
		if scrollView.zoomScale == scrollView.minimumZoomScale {
			scrollView.zoom(to: CGRect(origin: position, size: .zero), animated: true)
		} else {
			scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
		}
	}
	
	private var transition: UIPercentDrivenInteractiveTransition?
	@IBAction func viewDragged(_ panRecognizer: UIPanGestureRecognizer) {
		let translation = panRecognizer.translation(in: view)
		let velocity = panRecognizer.velocity(in: view)
		let progress = translation.y / view.bounds.height
		
		switch panRecognizer.state {
		case .began:
			transition = .init()
			dismiss(animated: true)
		case .changed:
			transition!.update(progress)
		case .ended:
			let progressVelocity = velocity.y / view.bounds.height
			if progress + 0.25 * progressVelocity > 0.5 {
				transition!.finish()
			} else {
				transition!.cancel()
			}
			transition = nil
		case .cancelled, .failed:
			transition!.cancel()
			transition = nil
		case .possible:
			break
		@unknown default:
			break
		}
	}
}

extension LightboxViewController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return PresentAnimator()
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return DismissAnimator()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return transition
	}
}

/// slides up and fades in black background
fileprivate final class PresentAnimator: TransitionAnimator {
	override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let fromVC = transitionContext.viewController(forKey: .from)!
		let lightboxController = transitionContext.viewController(forKey: .to) as! LightboxViewController
		lightboxController.view.layoutIfNeeded()
		
		transitionContext.containerView.insertSubview(lightboxController.view, aboveSubview: fromVC.view)
		
		let offset = lightboxController.view.bounds.height
		let pulledView = lightboxController.imageView!
		let finalFrame = pulledView.frame
		pulledView.frame = pulledView.frame.offsetBy(dx: 0, dy: offset)
		lightboxController.view.backgroundColor = .clear
		
		animate(using: transitionContext) {
			pulledView.frame = finalFrame
			lightboxController.view.backgroundColor = .black
		}
	}
}

/// slides down and fades out black background
fileprivate final class DismissAnimator: TransitionAnimator {
	override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let lightboxController = transitionContext.viewController(forKey: .from) as! LightboxViewController
		let toVC = transitionContext.viewController(forKey: .to)!
		
		transitionContext.containerView.insertSubview(toVC.view, belowSubview: lightboxController.view)
		
		let offset = lightboxController.view.bounds.height
		let pulledView = lightboxController.imageView!
		let finalFrame = pulledView.frame.offsetBy(dx: 0, dy: offset)
		
		animate(using: transitionContext) {
			pulledView.frame = finalFrame
			lightboxController.view.backgroundColor = .clear
		}
	}
}
