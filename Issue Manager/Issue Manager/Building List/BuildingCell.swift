// Created by Julian Dunskus

import UIKit

fileprivate let shadowOpacity: Float = 0.2

class BuildingCell: UICollectionViewCell, LoadedCollectionCell {
	fileprivate typealias Localization = L10n.BuildingList.BuildingSummary
	
	static let reuseID = "Building Cell"
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var nameLabel: UILabel!
	@IBOutlet var openIssuesLabel: UILabel!
	@IBOutlet var totalIssuesLabel: UILabel!
	
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
	var isRefreshing = false {
		didSet {
			contentView.alpha = isRefreshing ? 0.25 : 1
			layer.shadowOpacity = isRefreshing ? 0.05 : shadowOpacity
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		contentView.layer.cornerRadius = 8
		contentView.clipsToBounds = true
		layer.cornerRadius = 8
		
		layer.shadowOpacity = shadowOpacity
		layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		layer.shadowOffset = CGSize(width: 0, height: 6)
		layer.shadowRadius = 12
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
