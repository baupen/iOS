// Created by Julian Dunskus

import UIKit

extension UIView {
	var isShown: Bool {
		get { return !isHidden }
		set { isHidden = !newValue }
	}
	
	/// saves the current background color, calls `call`, and reassigns the saved background color
	func keepBackgroundColor(across call: () -> Void) {
		let color = backgroundColor
		call()
		backgroundColor = color
	}
}
