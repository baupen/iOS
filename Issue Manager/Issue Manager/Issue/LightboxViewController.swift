// Created by Julian Dunskus

import UIKit

final class LightboxViewController: UIViewController {
	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var aspectRatioConstraint: NSLayoutConstraint!
	
	@IBAction func dismissLightbox() {
		dismiss(animated: true)
	}
	
	var image: UIImage! {
		didSet {
			update()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	func update() {
		guard isViewLoaded, let image = image else { return }
		
		imageView.image = image
		aspectRatioConstraint.isActive = false
		aspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: image.size.width / image.size.height)
		aspectRatioConstraint.isActive = true
	}
	
	@IBAction func doubleTapped(_ tapRecognizer: UITapGestureRecognizer) {
		guard tapRecognizer.state == .ended else { return }
		
		let position = tapRecognizer.location(in: imageView)
		if scrollView.zoomScale == scrollView.minimumZoomScale {
			scrollView.zoom(to: CGRect(origin: position, size: .zero), animated: true)
		} else {
			scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
		}
	}
}
