import UIKit

extension NSLayoutConstraint {
	/// this value overrides the constant set when running below iOS 13
	@IBInspectable
	var legacyConstant: CGFloat {
		get { constant }
		set {
			if #available(iOS 13, *) {} else {
				constant = newValue
			}
		}
	}
}
