// Created by Julian Dunskus

import UIKit

final class FakePanRecognizer: UIPanGestureRecognizer {
	var fakeTranslation = CGPoint.zero {
		didSet {
			let now = Date()
			if let previousTime = lastUpdateTime {
				let difference = now.timeIntervalSince(previousTime)
				fakeVelocity = (fakeTranslation - oldValue) / CGFloat(difference)
			}
			lastUpdateTime = now
		}
	}
	var fakeVelocity = CGPoint.zero
	var lastUpdateTime: Date?
	private var fakeState = State.possible
	
	override var state: State {
		get { return fakeState }
		set { fakeState = newValue }
	}
	
	override func translation(in view: UIView?) -> CGPoint {
		return fakeTranslation
	}
	
	override func velocity(in view: UIView?) -> CGPoint {
		return fakeVelocity
	}
}
