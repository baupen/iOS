// Created by Julian Dunskus

import UIKit

class BuildingListLayout: UICollectionViewFlowLayout {
	override func prepare() {
		super.prepare()
		
		guard let collectionView = collectionView else { return }
		
		let size = collectionView.bounds.size
		let inset = sectionInset
		itemSize = size - CGSize(width: inset.left + inset.right, height: inset.top + inset.bottom)
	}
	
	// snaps cells to bounds; relies on the layout being a single horizontally scrolling list
	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
		guard proposedContentOffset.x > 0 else { return proposedContentOffset }
		
		let offset = minimumLineSpacing / 2
		let lineDistance = itemSize.width + minimumLineSpacing
		let offsetWithinCell = proposedContentOffset.x.truncatingRemainder(dividingBy: lineDistance) - offset
		let rounded = (offsetWithinCell / lineDistance).rounded() * lineDistance
		let offsetWithinView = (proposedContentOffset.x / lineDistance).rounded(.down) * lineDistance
		let targetOffset = offsetWithinView + rounded
		return CGPoint(x: targetOffset, y: proposedContentOffset.y)
	}
	
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		return true
	}
}
