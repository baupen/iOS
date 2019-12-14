// Created by Julian Dunskus

import UIKit
import CGeometry

final class LightboxViewController: UIViewController {
	@IBOutlet private var scrollView: UIScrollView!
	@IBOutlet fileprivate var imageView: UIImageView!
	@IBOutlet private var aspectRatioConstraint: NSLayoutConstraint!
	
	var sourceView: UIView?
	
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
	
	override var prefersStatusBarHidden: Bool {
		isFullyShown ? true : super.prefersStatusBarHidden
	}
	
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
		let translation = CGVector(panRecognizer.translation(in: view))
		let velocity = CGVector(panRecognizer.velocity(in: view))
		
		let viewDiagonal = CGVector(view.bounds.size).length
		let progress = translation.length / viewDiagonal
		
		switch panRecognizer.state {
		case .began:
			transition = .init()
			dismiss(animated: true)
		case .changed:
			transition!.update(progress)
		case .ended:
			let progressVelocity = velocity.length / viewDiagonal
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
		PresentAnimator()
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		DismissAnimator()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		transition
	}
}

/// slides up and fades in black background
fileprivate final class PresentAnimator: TransitionAnimator {
	override func animateTransition(using transitionContext: Context) {
		let fromVC = transitionContext.viewController(forKey: .from)!
		let lightboxController = transitionContext.viewController(forKey: .to) as! LightboxViewController
		lightboxController.view.layoutIfNeeded()
		
		transitionContext.containerView.insertSubview(lightboxController.view, aboveSubview: fromVC.view)
		lightboxController.view.frame = transitionContext.finalFrame(for: lightboxController)
		
		let offset = lightboxController.view.bounds.height
		let pulledView = lightboxController.imageView!
		let finalFrame = pulledView.frame
		if let sourceView = lightboxController.sourceView {
			pulledView.frame = sourceView.convert(sourceView.bounds, to: pulledView.superview!)
			sourceView.isHidden = true
		} else {
			pulledView.frame = pulledView.frame.offsetBy(dx: 0, dy: offset)
		}
		lightboxController.view.backgroundColor = .clear
		
		animate(using: transitionContext, animations: {
			pulledView.frame = finalFrame
			lightboxController.view.backgroundColor = .black
		}) { wasCancelled in
			lightboxController.sourceView?.isHidden = false
		}
	}
}

/// slides down and fades out black background
fileprivate final class DismissAnimator: TransitionAnimator {
	override func animateTransition(using transitionContext: Context) {
		let lightboxController = transitionContext.viewController(forKey: .from) as! LightboxViewController
		let toVC = transitionContext.viewController(forKey: .to)!
		
		if #available(iOS 13, *) {} else { // this seems to be done for us on iOS 13
			transitionContext.containerView.insertSubview(toVC.view, belowSubview: lightboxController.view)
			toVC.view.frame = transitionContext.finalFrame(for: toVC)
		}
		
		let pulledView = lightboxController.imageView!
		
		animate(using: transitionContext) {
			pulledView.transform = pulledView.transform.scaledBy(x: 1e-9, y: 1e-9)
			lightboxController.view.backgroundColor = .clear
		}
	}
}
