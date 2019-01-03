// Created by Julian Dunskus

import UIKit

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
			x: point.x,
			y: point.y
		)
	}
}

extension Rectangle {
	init(_ rect: CGRect) {
		self.init(
			x: Double(rect.origin.x),
			y: Double(rect.origin.y),
			width: Double(rect.width),
			height: Double(rect.height)
		)
	}
}

extension CGRect {
	init(_ rect: Rectangle) {
		self.init(
			x: rect.x,
			y: rect.y,
			width: rect.width,
			height: rect.height
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
