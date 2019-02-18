// Created by Julian Dunskus

import UIKit

extension UILabel {
	func setText(to text: String?, fallback: String) {
		self.text = text ?? fallback
		self.alpha = text != nil ? 1 : 0.5
	}
}
