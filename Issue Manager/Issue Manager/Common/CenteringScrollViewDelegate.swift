// Created by Julian Dunskus

import UIKit
import CGeometry

@MainActor
final class CenteringScrollViewDelegate: NSObject, UIScrollViewDelegate {
	@IBOutlet private weak var viewForZooming: UIView?
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		centerContent(of: scrollView) // initial setup, if needed
		return viewForZooming
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		centerContent(of: scrollView)
	}
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		centerContent(of: scrollView)
	}
	
	func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
		centerContent(of: scrollView)
	}
	
	func centerContent(of scrollView: UIScrollView) {
		let offset = 0.5 * (scrollView.bounds.size - scrollView.contentSize).map { max(0, $0) }
		scrollView.contentInset = UIEdgeInsets(
			top: offset.height,
			left: offset.width,
			bottom: 0,
			right: 0
		)
	}
}
