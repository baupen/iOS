// Created by Julian Dunskus

import UIKit

extension UIViewController {
	func showAlert(
		titled title: String?,
		message: String?,
		canCancel: Bool = false,
		okMessage: String = L10n.Alert.okay,
		okStyle: UIAlertAction.Style = .default,
		okHandler: (() -> Void)? = nil
	) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		if canCancel {
			alert.addAction(UIAlertAction(title: L10n.Alert.cancel, style: .cancel, handler: nil))
		}
		alert.addAction(UIAlertAction(title: okMessage, style: okStyle) { _ in
			okHandler?()
		})
		present(alert, animated: true)
	}
	
	func embed(_ child: UIViewController, within view: UIView) {
		addChild(child)
		view.addSubview(child.view)
		child.didMove(toParent: self)
	}
	
	func unembed(_ child: UIViewController) {
		child.willMove(toParent: nil)
		child.view.removeFromSuperview()
		child.removeFromParent()
	}
}
