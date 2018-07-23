// Created by Julian Dunskus

import UIKit

fileprivate let unitRect = CGRect(origin: .zero, size: .one)

class MarkupNavigationController: UINavigationController {
	var markupController: MarkupViewController {
		return topViewController as! MarkupViewController
	}
}

class MarkupViewController: UIViewController {
	@IBOutlet var backgroundView: UIImageView!
	@IBOutlet var foregroundView: UIImageView!
	@IBOutlet var wipView: UIImageView!
	
	@IBOutlet var aspectRatioConstraint: NSLayoutConstraint!
	@IBOutlet var colorChangeButtons: [ColorChangeButton]!
	@IBOutlet var modeButtons: [UIButton]!
	
	@IBAction func changeColor(_ sender: ColorChangeButton) {
		colorChangeButtons.forEach { $0.isChosen = $0 === sender }
		wipContext.setStrokeColor(sender.color.cgColor)
	}
	
	@IBAction func changeMode(_ sender: UIButton) {
		mode = Mode(rawValue: sender.tag)!
		print("switched to mode", sender.tag)
	}
	
	var image: UIImage! {
		didSet {
			update()
		}
	}
	
	var mode: Mode! {
		didSet {
			modeButtons.forEach { $0.isSelected = $0.tag == mode.rawValue }
		}
	}
	
	var drawingContext: CGContext!
	var wipContext: CGContext!
	
	private var hasDrawn = false
	private var displayLink: CADisplayLink?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mode = .freeDraw
		
		update()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		displayLink = CADisplayLink(target: self, selector: #selector(updateImage))
		displayLink?.add(to: .main, forMode: .commonModes)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		displayLink?.invalidate()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "save":
			wipContext.saveGState()
			defer { wipContext.restoreGState() }
			
			wipContext.draw(image.cgImage!, in: unitRect)
			wipContext.translateBy(x: 0, y: 1)
			wipContext.scaleBy(x: 1, y: -1)
			wipContext.draw(drawingContext.makeImage()!, in: unitRect)
			let newImage = UIImage(cgImage: wipContext.makeImage()!)
			
			let editIssueController = segue.destination as! EditIssueViewController
			editIssueController.image = newImage
		case "cancel":
			break
		default:
			fatalError("unrecognized segue with identifier \(segue.identifier ?? "<no identifier>")")
		}
	}
	
	func update() {
		guard isViewLoaded, let image = image else { return }
		
		backgroundView.image = image
		aspectRatioConstraint.isActive = false
		aspectRatioConstraint = backgroundView.widthAnchor.constraint(equalTo: backgroundView.heightAnchor, multiplier: image.size.width / image.size.height)
		aspectRatioConstraint.isActive = true
		
		drawingContext = makeContext(size: image.size)
		wipContext = makeContext(size: image.size)
	}
	
	private func makeContext(size: CGSize) -> CGContext {
		UIGraphicsBeginImageContextWithOptions(image.size, false, 1) // not opaque
		let context = UIGraphicsGetCurrentContext()!
		UIGraphicsEndImageContext()
		
		context.scaleBy(x: image.size.width, y: image.size.height) // normalize to 0...1
		context.setLineWidth(0.01)
		context.setStrokeColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
		context.setLineCap(.round)
		context.setLineJoin(.round)
		
		return context
	}
	
	@objc func updateImage() {
		if hasDrawn {
			wipView.image = UIImage(cgImage: wipContext.makeImage()!)
		}
	}
	
	private var startPosition: CGPoint!
	private var lastPosition: CGPoint!
	@IBAction func fingerDragged(_ panRecognizer: UIPanGestureRecognizer) {
		let position = panRecognizer.location(in: foregroundView) / foregroundView.bounds.size
		
		switch panRecognizer.state {
		case .began:
			startPosition = position
			lastPosition = position
			fallthrough
		case .changed:
			switch mode! {
			case .freeDraw:
				wipContext.move(to: lastPosition)
				wipContext.addLine(to: position)
				wipContext.strokePath()
			case .rectangle:
				wipContext.clear(unitRect)
				wipContext.stroke(CGRect(origin: startPosition, size: (position - startPosition).asSize))
			case .circle:
				wipContext.clear(unitRect)
				wipContext.strokeEllipse(in: CGRect(origin: startPosition, size: (position - startPosition).asSize))
			}
			
			lastPosition = position
		case .ended:
			drawingContext.saveGState()
			defer { drawingContext.restoreGState() }
			
			drawingContext.translateBy(x: 0, y: 1)
			drawingContext.scaleBy(x: 1, y: -1)
			drawingContext.draw(wipContext.makeImage()!, in: unitRect)
			foregroundView.image = UIImage(cgImage: drawingContext.makeImage()!)
			
			fallthrough
		case .cancelled, .failed:
			wipContext.clear(unitRect)
			lastPosition = nil
		case .possible:
			break
		}
		
		hasDrawn = true
	}
	
	enum Mode: Int {
		case freeDraw = 0
		case rectangle = 1
		case circle = 2
	}
}

class ModeChangeButton: UIButton {
	override var isSelected: Bool {
		didSet { tintColor = isSelected ? .main : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.25) }
	}
}
