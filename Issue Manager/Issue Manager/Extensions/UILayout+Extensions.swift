// Created by Julian Dunskus

import UIKit

extension UILayoutPriority: ExpressibleByFloatLiteral {
	public init(floatLiteral value: Float) {
		self.init(value)
	}
}

extension UIView.AutoresizingMask {
	static let flexibleSize: UIView.AutoresizingMask = [
		flexibleWidth,
		flexibleHeight
	]
	
	static let flexibleMargins: UIView.AutoresizingMask = [
		flexibleTopMargin,
		flexibleBottomMargin,
		flexibleLeftMargin,
		flexibleRightMargin
	]
}
