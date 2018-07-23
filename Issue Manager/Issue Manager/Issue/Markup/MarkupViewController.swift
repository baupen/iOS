// Created by Julian Dunskus

import UIKit

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
		guard isSelectingColor else {
			isSelectingColor = true
			return
		}
		
		colorChangeButtons.forEach { $0.isChosen = $0 === sender }
		wipContext.setStrokeColor(sender.color.cgColor)
		isSelectingColor = false
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
	
	private var mode: Mode! {
		didSet {
			modeButtons.forEach { $0.isSelected = $0.tag == mode.rawValue }
		}
	}
	
	var drawingContext: CGContext!
	var wipContext: CGContext!
	
	private var hasDrawn = false
	private var displayLink: CADisplayLink?
	private var fullRect: CGRect {
		return CGRect(origin: .zero, size: image.size)
	}
	private var undoBuffer = UndoBuffer<CGImage>(size: 5)
	
	private var isSelectingColor = false {
		didSet {
			UIView.animate(withDuration: 0.1) { [isSelectingColor] in
				self.colorChangeButtons.forEach { $0.isShown = isSelectingColor || $0.isChosen }
				self.modeButtons.forEach { $0.isHidden = isSelectingColor }
				self.view.layoutIfNeeded()
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mode = .freeDraw
		self.colorChangeButtons.forEach { $0.isShown = $0.isChosen }
		
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
			
			wipContext.draw(image.cgImage!, in: fullRect)
			wipContext.translateBy(x: 0, y: image.size.height)
			wipContext.scaleBy(x: 1, y: -1)
			wipContext.draw(drawingContext.makeImage()!, in: fullRect)
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
		
		context.setLineWidth(0.01 * min(image.size.width, image.size.height))
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
	// pan recognizers have a slight delay before they activate, unlike long press recognizers (which are more customizable)
	@IBAction func fingerDragged(_ recognizer: UILongPressGestureRecognizer) {
		let position = recognizer.location(in: foregroundView) / foregroundView.bounds.size * image.size
		
		switch recognizer.state {
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
				wipContext.clear(fullRect)
				wipContext.stroke(CGRect(origin: startPosition, size: (position - startPosition).asSize))
			case .circle:
				wipContext.clear(fullRect)
				wipContext.strokeEllipse(in: CGRect(origin: startPosition, size: (position - startPosition).asSize))
			}
			
			lastPosition = position
		case .ended:
			drawingContext.saveGState()
			defer { drawingContext.restoreGState() }
			
			drawingContext.translateBy(x: 0, y: image.size.height)
			drawingContext.scaleBy(x: 1, y: -1)
			drawingContext.draw(wipContext.makeImage()!, in: fullRect)
			foregroundView.image = UIImage(cgImage: drawingContext.makeImage()!)
			
			fallthrough
		case .cancelled, .failed:
			wipContext.clear(fullRect)
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
