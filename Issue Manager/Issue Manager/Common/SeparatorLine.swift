// Created by Julian Dunskus

import UIKit

fileprivate var color: UIColor = {
	if #available(iOS 13.0, *) {
		return .separator
	} else {
		return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.25)
	}
}()

@IBDesignable
final class SeparatorLine: UIView {
	override var backgroundColor: UIColor? {
		didSet {
			if backgroundColor != color {
				backgroundColor = color
			}
		}
	}
	
	override var intrinsicContentSize: CGSize {
		CGSize(width: UIView.noIntrinsicMetric, height: 1 / UIScreen.main.scale)
	}
}
