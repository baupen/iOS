// Created by Julian Dunskus

import UIKit

@IBDesignable
final class SeparatorLine: UIView {
	override var intrinsicContentSize: CGSize {
		CGSize(width: UIView.noIntrinsicMetric, height: 1 / UIScreen.main.scale)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		backgroundColor = .separator
	}
}
