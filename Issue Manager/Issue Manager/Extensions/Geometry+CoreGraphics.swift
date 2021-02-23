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
