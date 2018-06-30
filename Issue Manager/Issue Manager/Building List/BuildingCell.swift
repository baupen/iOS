// Created by Julian Dunskus

import UIKit

class BuildingCell: UICollectionViewCell, LoadedCollectionCell {
	static let reuseID = "Building Cell"
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var nameLabel: UILabel!
	
	var building: Building! {
		didSet {
			nameLabel.text = building.name
			updateImage()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		contentView.layer.cornerRadius = 8
		contentView.clipsToBounds = true
		layer.cornerRadius = 8
		
		layer.shadowOpacity = 0.2
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
