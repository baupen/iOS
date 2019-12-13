// Created by Julian Dunskus

import UIKit

final class SiteListLayout: UICollectionViewFlowLayout {
	override func prepare() {
		super.prepare()
		
		guard let collectionView = collectionView else { return }
		
		let availableSize = collectionView.bounds
			.inset(by: collectionView.adjustedContentInset)
			.inset(by: sectionInset)
			.size
		let minimumWidth: CGFloat = 300
		let spacing = minimumLineSpacing
		let amount = max(1, ((availableSize.width + spacing) / (minimumWidth + spacing)).rounded(.down))
		let cellWidth = (availableSize.width - (amount - 1) * spacing) / amount
		itemSize = CGSize(width: cellWidth, height: availableSize.height)
	}
	
	// snaps cells to bounds; relies on the layout being a single horizontally scrolling list
	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
		let leftInset = collectionView!.adjustedContentInset.left
		let proposedX = proposedContentOffset.x + leftInset
		guard proposedX > 0 else { return proposedContentOffset }
		
		let offset = minimumLineSpacing / 2
		let lineDistance = itemSize.width + minimumLineSpacing
		let offsetWithinCell = proposedX.truncatingRemainder(dividingBy: lineDistance) - offset
		let rounded = (offsetWithinCell / lineDistance).rounded() * lineDistance
		let offsetWithinView = (proposedX / lineDistance).rounded(.down) * lineDistance
		let targetOffset = offsetWithinView + rounded - leftInset
		return CGPoint(x: targetOffset, y: proposedContentOffset.y)
	}
	
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }
}
