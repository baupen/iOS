// Created by Julian Dunskus

import UIKit

final class DrawingView: UIView {
	/// - note: make _very_ sure you're not causing a retain cycle here, e.g. by using `unowned self`
	var drawingBlock: ((CGRect) -> Void)!
	
	override func draw(_ rect: CGRect) {
		drawingBlock(rect)
	}
}
