// Created by Julian Dunskus

import UIKit
import CGeometry

fileprivate let markerSize = CGSize(width: 32, height: 32)

final class IssueMarker: UIView {
	let issue: Issue
	
	var zoomScale: CGFloat = 1 {
		didSet { resize() }
	}
	
	var buttonAction: (() -> Void)!
	
	private let button = UIButton()
	
	init(issue: Issue) {
		self.issue = issue
		
		super.init(frame: CGRect(origin: .zero, size: markerSize))
		autoresizingMask = .flexibleMargins // keep relative position during superview resize
		
		addSubview(button)
		button.frame = self.bounds
		button.autoresizingMask = .flexibleSize
		button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
	}
	
	required init?(coder: NSCoder) {
		fatalError()
	}
	
	func matchesFilter() -> Bool {
		ViewOptions.shared.shouldDisplay(issue)
	}
	
	@objc func buttonPressed(_ sender: UIButton) {
		buttonAction()
	}
	
	func update() {
		button.setImage(issue.status.stage.shadedIcon, for: .normal)
		updateVisibility()
		reposition()
	}
	
	func updateVisibility() {
		isHidden = !matchesFilter() || issue.position == nil
	}
	
	private func resize() {
		// for some reason the size is rounded to nearest integer values anyway, but the view is off-center if that happens, so it's best to manually round it here.
		let idealSize = markerSize.map { $0 / zoomScale }
		let roundedSize = idealSize.map { max(round($0), 1) }
		bounds.size = roundedSize
		transform = CGAffineTransform.identity.scaledBy(
			x: idealSize.width / roundedSize.width,
			y: idealSize.height / roundedSize.height
		)
	}
	
	private func reposition() {
		guard let position = issue.position?.point else { return }
		
		center.x = CGFloat(position.x) * superview!.bounds.width
		center.y = CGFloat(position.y) * superview!.bounds.height
	}
}
