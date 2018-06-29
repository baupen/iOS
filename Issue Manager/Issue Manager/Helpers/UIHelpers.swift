// Created by Julian Dunskus

import UIKit

extension UISplitViewController {
	func toggleMasterView() {
		// only slightly hacky
		let button = displayModeButtonItem
		UIApplication.shared.sendAction(button.action!, to: button.target!, from: nil, for: nil)
	}
}

extension UIViewController {
	func showAlert(titled title: String?,
				   message: String?,
				   canCancel: Bool = false,
				   okMessage: String = "Okay", // TODO localize
				   okStyle: UIAlertActionStyle = .default,
				   okHandler: (() -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		if canCancel {
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		}
		alert.addAction(UIAlertAction(title: okMessage, style: okStyle) { _ in
			okHandler?()
		})
		present(alert, animated: true)
	}
}

extension UIImage {
	func applyingOrientation() -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		defer { UIGraphicsEndImageContext() }
		draw(in: CGRect(origin: .zero, size: size))
		return UIGraphicsGetImageFromCurrentImageContext()!
	}
}
