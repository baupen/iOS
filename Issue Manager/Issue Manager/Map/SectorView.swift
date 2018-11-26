// Created by Julian Dunskus

import UIKit

final class SectorView: UIView {
	let sector: Map.Sector
	
	private var path: CGPath!
	private var isHighlighted = false {
		didSet {
			guard isHighlighted != oldValue else { return }
			UIView.animate(withDuration: 0.1) { [isHighlighted] in
				self.alpha = isHighlighted ? 0.8 : 0.3
			}
		}
	}
	
	init(_ sector: Map.Sector) {
		self.sector = sector
		
		super.init(frame: .zero)
		autoresizingMask = [ // keep relative position and size during superview resize
			.flexibleTopMargin,
			.flexibleBottomMargin,
			.flexibleLeftMargin,
			.flexibleRightMargin,
			.flexibleWidth,
			.flexibleHeight
		]
		
		isOpaque = false
		alpha = 0.3
		
		let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
		longPressRecognizer.minimumPressDuration = 0.1
		longPressRecognizer.allowableMovement = 1
		addGestureRecognizer(longPressRecognizer)
		
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		addGestureRecognizer(tapRecognizer)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
	
	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		
		if let superview = superview {
			let scaledPoints = sector.points
				.map(CGPoint.init)
				.map { $0 * superview.bounds.size }
			
			path = CGMutablePath() <- {
				$0.addLines(between: scaledPoints)
				$0.closeSubpath()
			}
			
			frame = path.boundingBox
		}
	}
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard super.point(inside: point, with: event) else { return false }
		
		return path.contains(point + frame.origin)
	}
	
	override func draw(_ rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()!
		context.translateBy(x: -frame.origin.x, y: -frame.origin.y)
		
		context.setLineWidth(0.005 * superview!.bounds.size.length)
		
		let color = sector.color.map(UIColor.init) ?? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
		context.setFillColor(color.withAlphaComponent(0.5).cgColor)
		context.setStrokeColor(color.cgColor)
		
		context.addPath(path)
		context.clip()
		
		context.addPath(path)
		context.fillPath()
		
		context.addPath(path)
		context.strokePath()
	}
	
	@objc func handleTap(_ recognizer: UIGestureRecognizer) {
		let isInside = point(inside: recognizer.location(in: self), with: nil)
		switch recognizer.state {
		case .began:
			isHighlighted = true
		case .changed:
			isHighlighted = isInside
		case .ended:
			if isInside {
				print("tap recognized!")
				// TODO: delegate thingy
			}
			fallthrough
		case .cancelled:
			isHighlighted = false
		case .failed, .possible:
			break
		}
	}
}
