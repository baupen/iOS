// Created by Julian Dunskus

import UIKit

final class LightboxViewController: UIViewController {
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
}
