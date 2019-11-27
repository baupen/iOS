// Created by Julian Dunskus

import UIKit

final class CenteringScrollViewDelegate: NSObject, UIScrollViewDelegate {
	@IBOutlet private weak var viewForZooming: UIView?
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		centerContent(of: scrollView) // initial setup, if needed
		return viewForZooming
	}
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		centerContent(of: scrollView)
	}
	
	func centerContent(of scrollView: UIScrollView) {
		let offset = 0.5 * (scrollView.bounds.size - scrollView.contentSize).map { max(0, $0) }
		scrollView.contentInset = UIEdgeInsets(top: offset.y, left: offset.x, bottom: 0, right: 0)
	}
}
