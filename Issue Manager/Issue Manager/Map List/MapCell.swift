// Created by Julian Dunskus

import UIKit

class MapCell: UITableViewCell, LoadedTableCell {
	static let reuseID = "Map Cell"
	
	@IBOutlet weak var nameLabel: UILabel?
	
	var map: Map? {
		didSet {
			reload()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		reload()
	}
	
	func reload() {
		nameLabel?.text = map?.name
	}
}
