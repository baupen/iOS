// Created by Julian Dunskus

import UIKit
import CGeometry

final class IssuePositioner: UIView {
	@IBOutlet private var crosshairView: UIImageView!
	@IBOutlet private var topView: UIView!
	@IBOutlet private var botView: UIView!
	
	override var center: CGPoint {
		didSet {
			let threshold: CGFloat = 0.35
			if center.y < superview!.bounds.height * threshold {
				topView.isHidden = true
				botView.isHidden = false
			} else if center.y > superview!.bounds.height * (1 - threshold) {
				topView.isHidden = false
				botView.isHidden = true
			}
		}
	}
	
	func relativePosition(in view: UIView) -> CGPoint {
		let center = view.convert(self.center, from: superview!)
		return (center / view.bounds.size)
			.map { min(1, max(0, $0)) }
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		crosshairView.layer.shadowOpacity = 1
		crosshairView.layer.shadowOffset = .zero
		crosshairView.layer.shadowRadius = 4
		crosshairView.layer.shadowColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		
		let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
		panRecognizer.delegate = self
		addGestureRecognizer(panRecognizer)
	}
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		return crosshairView.frame.contains(point)
			|| !topView.isHidden && topView.point(inside: topView.convert(point, from: self), with: event)
			|| !botView.isHidden && botView.point(inside: botView.convert(point, from: self), with: event)
	}
	
	var startOffset: CGPoint!
	@objc func viewPanned(_ recognizer: UIPanGestureRecognizer) {
		let translation = CGVector(recognizer.translation(in: self))
		
		switch recognizer.state {
		case .began:
			startOffset = center
			fallthrough
		case .changed:
			center = startOffset + translation
		case .cancelled, .ended, .failed:
			startOffset = nil
		case .possible:
			break
		@unknown default:
			break
		}
	}
}

extension IssuePositioner: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return touch.view == crosshairView
	}
}

extension Issue.Position {
	init(at point: CGPoint, zoomScale: CGFloat, in file: File<Map>) {
		self.init(
			at: Point(point),
			zoomScale: Double(1 / zoomScale),
			in: file
		)
	}
}
