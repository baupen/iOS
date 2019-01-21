// Created by Julian Dunskus

import UIKit

@IBDesignable
final class ColorChangeButton: UIButton {
	@IBInspectable var isChosen: Bool = false {
		didSet { updateAppearance() }
	}
	
	var color: UIColor {
		return backgroundColor!
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		setUp()
	}
	
	override func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		
		setUp()
	}
	
	func setUp() {
		backgroundColor = color
		
		updateAppearance()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		layer.cornerRadius = bounds.height / 2
	}
	
	func updateAppearance() {
		layer.borderColor = color == .black ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.25)
		layer.borderWidth = isChosen ? 4 : 1
	}
}
