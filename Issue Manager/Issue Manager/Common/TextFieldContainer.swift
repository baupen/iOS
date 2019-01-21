// Created by Julian Dunskus

import UIKit

final class TextFieldContainer: UIView {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRecognized))
		addGestureRecognizer(tapRecognizer)
	}
	
	@objc func tapRecognized(_ sender: UITapGestureRecognizer) {
		assert(subviews.count == 1)
		if let textField = subviews.first as? UITextField {
			textField.becomeFirstResponder()
		} else {
			assertionFailure()
		}
	}
}
