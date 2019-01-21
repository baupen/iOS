// Created by Julian Dunskus

import UIKit

final class MarkupNavigationController: UINavigationController {
	var markupController: MarkupViewController {
		return topViewController as! MarkupViewController
	}
}

final class MarkupViewController: UIViewController {
	@IBOutlet var backgroundView: UIImageView!
	@IBOutlet var foregroundView: UIImageView!
	@IBOutlet var wipView: UIImageView!
	
	@IBOutlet var aspectRatioConstraint: NSLayoutConstraint!
	@IBOutlet var colorChangeButtons: [ColorChangeButton]!
	@IBOutlet var modeButtons: [UIButton]!
	
	@IBOutlet var undoButton: UIButton!
	@IBOutlet var redoButton: UIButton!
	
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
	}
	
	@IBAction func undo() {
		undo(to: undoBuffer.undo())
	}
	
	@IBAction func redo() {
		undo(to: undoBuffer.redo())
	}
	
	var image: UIImage! {
		didSet { update() }
	}
	
	private var mode: Mode! {
		didSet {
			modeButtons.forEach { $0.isSelected = $0.tag == mode.rawValue }
		}
	}
	
	private var drawingContext: CGContext!
	private var wipContext: CGContext!
	
	private var displayLink: CADisplayLink!
	private var fullRect: CGRect {
		return CGRect(origin: .zero, size: image.size)
	}
	private var undoBuffer: UndoBuffer<CGImage>!
	
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
		
		update()
		
		mode = .freeDraw
		colorChangeButtons.forEach { $0.isShown = $0.isChosen }
		updateUndoButtons()
		
		displayLink = CADisplayLink(target: self, selector: #selector(updateImage))
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		displayLink.invalidate()
		displayLink = nil // release, because apparently invalidate() doesn't release us
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "save":
			wipContext.saveGState()
			defer { wipContext.restoreGState() }
			
			wipContext.translateBy(x: 0, y: image.size.height)
			wipContext.scaleBy(x: 1, y: -1)
			wipContext.draw(image.cgImage!, in: fullRect)
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
	
	private var imageUnit: CGFloat!
	private func update() {
		guard isViewLoaded, let image = image else { return }
		
		imageUnit = 0.01 * min(image.size.width, image.size.height)
		
		backgroundView.image = image
		aspectRatioConstraint.isActive = false
		aspectRatioConstraint = backgroundView.widthAnchor.constraint(equalTo: backgroundView.heightAnchor, multiplier: image.size.width / image.size.height)
		aspectRatioConstraint.isActive = true
		
		drawingContext = makeContext(size: image.size)
		wipContext = makeContext(size: image.size)
		
		let imageSize = image.cgImage!.width * image.cgImage!.bytesPerRow
		let allowedSize = 200 << 20 // 200 MB
		undoBuffer = UndoBuffer(size: allowedSize / imageSize)
		print(undoBuffer.size)
		undoBuffer.push(drawingContext.makeImage()!) // empty base state
	}
	
	private func makeContext(size: CGSize) -> CGContext {
		UIGraphicsBeginImageContextWithOptions(image.size, false, 1) // not opaque
		let context = UIGraphicsGetCurrentContext()!
		UIGraphicsEndImageContext()
		
		context.setLineWidth(imageUnit)
		context.setStrokeColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
		context.setLineCap(.round)
		context.setLineJoin(.round)
		
		return context
	}
	
	@objc func updateImage() {
		wipView.image = UIImage(cgImage: wipContext.makeImage()!)
	}
	
	private func undo(to snapshot: CGImage) {
		drawingContext.clear(fullRect)
		draw(snapshot)
		foregroundView.image = UIImage(cgImage: snapshot)
		updateUndoButtons()
	}
	
	private func updateUndoButtons() {
		undoButton.isEnabled = undoBuffer.canUndo
		redoButton.isEnabled = undoBuffer.canRedo
	}
	
	private var startPosition: CGPoint!
	private var lastPosition: CGPoint!
	// pan recognizers have a slight delay before they activate, unlike long press recognizers (which are more customizable)
	@IBAction func fingerDragged(_ recognizer: UILongPressGestureRecognizer) {
		let position = recognizer.location(in: foregroundView) / foregroundView.bounds.size * image.size
		
		switch recognizer.state {
		case .began:
			displayLink.add(to: .main, forMode: .common)
			
			startPosition = position
			lastPosition = position
			fallthrough
		case .changed:
			let offset = position - startPosition
			
			switch mode! {
			case .freeDraw:
				wipContext.move(to: lastPosition)
				wipContext.addLine(to: position)
				wipContext.strokePath()
			case .rectangle:
				wipContext.clear(fullRect)
				wipContext.stroke(CGRect(origin: startPosition, size: offset.asSize))
			case .circle:
				wipContext.clear(fullRect)
				wipContext.strokeEllipse(in: CGRect(origin: startPosition - offset, size: 2 * offset.asSize))
			case .arrow:
				guard offset.length > 0 else { return } // pls no NaN
				wipContext.clear(fullRect)
				wipContext.move(to: startPosition)
				wipContext.addLine(to: position)
				let perpendicular = CGVector(dx: -offset.y, dy: offset.x)
				let tipLength = imageUnit * 5
				wipContext.move(to: position - (offset + perpendicular).withLength(tipLength))
				wipContext.addLine(to: position)
				wipContext.addLine(to: position - (offset - perpendicular).withLength(tipLength))
				wipContext.strokePath()
			}
			
			lastPosition = position
		case .ended:
			draw(wipContext.makeImage()!)
			
			let snapshot = drawingContext.makeImage()!
			foregroundView.image = UIImage(cgImage: snapshot)
			undoBuffer.push(snapshot)
			updateUndoButtons()
			
			fallthrough
		case .cancelled, .failed:
			wipContext.clear(fullRect)
			wipView.image = nil
			startPosition = nil
			lastPosition = nil
			
			displayLink.remove(from: .main, forMode: .common)
		case .possible:
			break
		}
	}
	
	func draw(_ snapshot: CGImage) {
		drawingContext.saveGState()
		defer { drawingContext.restoreGState() }
		
		drawingContext.translateBy(x: 0, y: image.size.height)
		drawingContext.scaleBy(x: 1, y: -1)
		drawingContext.draw(snapshot, in: fullRect)
	}
	
	enum Mode: Int {
		case freeDraw = 0
		case rectangle = 1
		case circle = 2
		case arrow = 3
	}
}

final class ModeChangeButton: UIButton {
	override var isSelected: Bool {
		didSet { tintColor = isSelected ? .main : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.25) }
	}
}

extension Vector2 {
	func withLength(_ length: CGFloat) -> Self {
		return self * length / self.length
	}
}
