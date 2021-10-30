// Created by Julian Dunskus

import UIKit

@IBDesignable
final class SeparatorLine: UIView {
	override var backgroundColor: UIColor? {
		get { .separator }
		set {}
	}
	
	override var intrinsicContentSize: CGSize {
		CGSize(width: UIView.noIntrinsicMetric, height: 1 / UIScreen.main.scale)
	}
}
