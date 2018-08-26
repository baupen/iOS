// Created by Julian Dunskus

import UIKit

class IssueBadge: UIView {
	let label = UILabel() <- {
		$0.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		$0.font = .systemFont(ofSize: 17, weight: .semibold)
		$0.textAlignment = .center
		
		$0.setContentHuggingPriority(800.0, for: .horizontal)
		$0.setContentHuggingPriority(.required, for: .vertical)
		$0.setContentCompressionResistancePriority(900.0, for: .horizontal)
		$0.setContentCompressionResistancePriority(.required, for: .vertical)
	}
	
	var shouldUseRecursiveIssues = true
	var holder: MapHolder! {
		didSet { update() }
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		widthAnchor.constraint(greaterThanOrEqualTo: heightAnchor, multiplier: 1.25).isActive = true
		
		label.text = "…"
		addSubview(label)
		
		label.translatesAutoresizingMaskIntoConstraints = false
		label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
		label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
		label.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
		label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
		
		backgroundColor = .attention
		clipsToBounds = true
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		layer.cornerRadius = bounds.height / 2
	}
	
	func update() {
		let issues = shouldUseRecursiveIssues
			? holder.recursiveIssues()
			: AnyCollection((holder as! Map).allIssues())
		// async because there could be a lot of issues (e.g. if we're calculating it for a whole building)
		let issueCount = BasicFuture(asyncOn: .global()) {
			issues.count { $0.hasResponse && $0.isOpen }
		}
		
		issueCount.on(.main).then { count in
			if count == 0 {
				self.isHidden = true
			} else {
				self.isHidden = false
				self.label.text = String(count)
				self.setNeedsLayout()
			}
		}
	}
}
