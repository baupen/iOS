// Created by Julian Dunskus

import UIKit

fileprivate var color = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.25)

class SeparatorLine: UIView {
	override var backgroundColor: UIColor? {
		didSet {
			if backgroundColor != color {
				backgroundColor = color
			}
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		frame.size.height = 1 / UIScreen.main.scale
	}
}
