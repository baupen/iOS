// Created by Julian Dunskus

import UIKit

fileprivate let shadowOpacity: Float = 0.2
fileprivate let shadowOffset = CGSize(width: 0, height: 6)
fileprivate let shadowRadius: CGFloat = 12

class BuildingCell: UICollectionViewCell, LoadedCollectionCell {
	fileprivate typealias Localization = L10n.BuildingList.BuildingSummary
	
	static let reuseID = "Building Cell"
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var nameLabel: UILabel!
	@IBOutlet var openIssuesLabel: UILabel!
	@IBOutlet var totalIssuesLabel: UILabel!
	
	override var isHighlighted: Bool {
		didSet {
			updateAppearance()
		}
	}
	
	var isRefreshing = false {
		didSet {
			updateAppearance()
		}
	}
	
	var building: Building! {
		didSet {
			updateImage()
			nameLabel.text = building.name
			DispatchQueue.global().async {
				let issues = self.building.allIssues()
				let openIssues = issues.filter { !$0.isReviewed }
				DispatchQueue.main.async {
					self.totalIssuesLabel.text = Localization.totalIssues(String(issues.count))
					self.openIssuesLabel.text = Localization.openIssues(String(openIssues.count))
				}
			}
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		contentView.layer.cornerRadius = 8
		contentView.clipsToBounds = true
		layer.cornerRadius = 8
		
		updateAppearance()
	}
	
	func updateAppearance() {
		UIView.animate(withDuration: 0.1) {
			self.contentView.alpha = self.isRefreshing ? 1 / 4 : 1
			self.layer.shadowOpacity = self.isRefreshing ? shadowOpacity / 4 : shadowOpacity
			
			let isHighlighted = self.isHighlighted
			self.contentView.backgroundColor = isHighlighted ? #colorLiteral(red: 0.2652326185, green: 0.2791550029, blue: 0.5412910581, alpha: 0.1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
			self.layer.shadowOffset = isHighlighted ? shadowOffset / 4 : shadowOffset
			self.layer.shadowRadius = isHighlighted ? shadowRadius / 4 : shadowRadius
			self.transform = isHighlighted ? .init(scaleX: 0.95, y: 0.95) : .identity
		}
	}
	
	private var imageTimer: Timer?
	func updateImage() {
		if let imageFilename = building.imageFilename {
			let imageURL = Building.cacheURL(filename: imageFilename)
			if let image = UIImage(contentsOfFile: imageURL.path) {
				imageView.image = image
				imageTimer?.invalidate()
			} else {
				// because images may not be downloaded right away and we don't have a callback for that
				imageTimer = .scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
					self.updateImage()
				}
			}
		}
	}
}