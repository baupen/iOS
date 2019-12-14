import UIKit

final class PassThroughView: UIView {
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let result = super.hitTest(point, with: event)
		return result == self ? nil : result
	}
}
