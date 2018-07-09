// Created by Julian Dunskus

import UIKit

fileprivate let markerSize = CGSize(width: 32, height: 32)

class IssueMarker: UIView {
	var issue: Issue!
	
	var zoomScale: CGFloat = 1 {
		didSet {
			resize()
		}
	}
	
	var buttonAction: (() -> Void)!
	
	private let button = UIButton()
	
	init() {
		super.init(frame: CGRect(origin: .zero, size: markerSize))
		autoresizingMask = [ // keep relative position during superview resize
			.flexibleTopMargin,
			.flexibleBottomMargin,
			.flexibleLeftMargin,
			.flexibleRightMargin,
		]
		
		addSubview(button)
		button.frame = self.bounds
		button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
	
	@objc func buttonPressed(_ sender: UIButton) {
		buttonAction()
	}
	
	func update() {
		let image: UIImage
		switch issue.status.simplified {
		case .new:
			image = #imageLiteral(resourceName: "issue_created.pdf")
		case .registered:
			image = #imageLiteral(resourceName: "issue_new.pdf")
		case .responded:
			image = #imageLiteral(resourceName: "issue_responded.pdf")
		case .reviewed:
			image = #imageLiteral(resourceName: "issue_reviewed.pdf")
		}
		button.setImage(image, for: .normal)
		
		reposition()
	}
	
	private func resize() {
		// for some reason the size is rounded to nearest integer values anyway, but the view is off-center if that happens, so it's best to manually round it here.
		bounds.size = markerSize
			.map { max(round($0 / zoomScale), 1) }
	}
	
	private func reposition() {
		center.x = superview!.bounds.width * CGFloat(issue.position!.x)
		center.y = superview!.bounds.height * CGFloat(issue.position!.y)
	}
}
