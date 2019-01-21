// Created by Julian Dunskus

import UIKit

@IBDesignable
final class LoginWindowView: UIView {
	override func prepareForInterfaceBuilder() {
		awakeFromNib()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		layer.cornerRadius = 16
		
		layer.shadowOpacity = 0.25
		layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		layer.shadowOffset = CGSize(width: 0, height: 16)
		layer.shadowRadius = 32
	}
}
