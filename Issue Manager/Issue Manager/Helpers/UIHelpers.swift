// Created by Julian Dunskus

import UIKit

extension UISplitViewController {
	func toggleMasterView() {
		// only slightly hacky
		let button = displayModeButtonItem
		UIApplication.shared.sendAction(button.action!, to: button.target!, from: nil, for: nil)
	}
}

extension UIViewController {
	func showAlert(
		titled title: String?,
		message: String?,
		canCancel: Bool = false,
		okMessage: String = L10n.Alert.okay,
		okStyle: UIAlertAction.Style = .default,
		okHandler: (() -> Void)? = nil
	) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		if canCancel {
			alert.addAction(UIAlertAction(title: L10n.Alert.cancel, style: .cancel, handler: nil))
		}
		alert.addAction(UIAlertAction(title: okMessage, style: okStyle) { _ in
			okHandler?()
		})
		present(alert, animated: true)
	}
}

extension UIViewController {
	func embed(_ child: UIViewController, within view: UIView) {
		addChild(child)
		view.addSubview(child.view)
		child.didMove(toParent: self)
	}
	
	func unembed(_ child: UIViewController) {
		child.willMove(toParent: nil)
		child.view.removeFromSuperview()
		child.removeFromParent()
	}
}

extension UILayoutPriority: ExpressibleByFloatLiteral {
	public init(floatLiteral value: Float) {
		self.init(value)
	}
}

extension UIView {
	var isShown: Bool {
		get { return !isHidden }
		set { isHidden = !newValue }
	}
	
	/// saves the current background color, calls `call`, and reassigns the saved background color
	func keepBackgroundColor(across call: () -> Void) {
		let color = backgroundColor
		call()
		backgroundColor = color
	}
}

extension UILabel {
	func setText(to text: String?, fallback: String) {
		self.text = text ?? fallback
		self.alpha = text != nil ? 1 : 0.5
	}
}

extension Collection {
	var nonEmptyOptional: Self? {
		return isEmpty ? nil : self
	}
}

extension Error {
	var localizedFailureReason: String {
		return (self as NSError).localizedFailureReason ?? localizedDescription
	}
}

extension Point {
	init(_ point: CGPoint) {
		self.init(
			x: Double(point.x),
			y: Double(point.y)
		)
	}
}

extension CGPoint {
	init(_ point: Point) {
		self.init(
			x: CGFloat(point.x),
			y: CGFloat(point.y)
		)
	}
}

extension UIColor {
	convenience init(_ color: Color) {
		self.init(
			red: CGFloat(color.red) / 255,
			green: CGFloat(color.green) / 255,
			blue: CGFloat(color.blue) / 255,
			alpha: 1
		)
	}
}

extension CGPath {
	static func polygon(corners: [CGPoint]) -> CGPath {
		return CGMutablePath() <- {
			$0.addLines(between: corners)
			$0.closeSubpath()
		}
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
