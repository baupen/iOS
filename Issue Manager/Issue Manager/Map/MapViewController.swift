// Created by Julian Dunskus

import UIKit

class MapViewController: UIViewController, LoadedViewController {
	static let storyboardID = "Map"
	
	@IBOutlet var testLabel: UILabel!
	
	var map: Map? {
		didSet {
			if let map = map {
				testLabel.text = """
				Showing \(map.name)!
				\(map.filename ?? "<no file>")
				"""
			} else {
				testLabel.text = "<no map>"
			}
		}
	}
}
