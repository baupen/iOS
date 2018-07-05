// Created by Julian Dunskus

import UIKit

class MapListViewController: UITableViewController {
	@IBOutlet var showMapButton: UIBarButtonItem!
	
	var source: MapSource! {
		didSet {
			navigationItem.title = source.name
			reload()
		}
	}
	
	var maps: [Map] = [] {
		didSet {
			tableView.reloadData()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		updateShowMapButton()
		
		super.viewWillAppear(animated)
	}
	
	func reload() {
		updateShowMapButton()
		
		maps = source.childMaps().sorted { $0.name < $1.name }
	}
	
	func updateShowMapButton() {
		showMapButton.isEnabled = source.filename != nil
		let isMapShown = splitViewController!.viewControllers.count == 2
		navigationItem.rightBarButtonItem = isMapShown ? nil : showMapButton
	}
	
	// MARK: - Table View
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return maps.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return tableView.dequeue(MapCell.self, for: indexPath)! <- {
			$0.map = maps[indexPath.row]
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let map = maps[indexPath.row]
		
		let mainController = splitViewController as! MainViewController
		
		let mapController: MapViewController
		if mainController.traitCollection.horizontalSizeClass == .regular {
			mapController = mainController.detailNav!.topViewController as! MapViewController
		} else {
			mapController = storyboard!.instantiate(MapViewController.self)!
			mapController.loadViewIfNeeded()
			show(mapController, sender: self)
		}
		mapController.map = map
	}
}

protocol MapSource {
	var name: String { get }
	var filename: String? { get }
	
	func childMaps() -> [Map]
	func allIssues() -> [Issue]
}

extension Building: MapSource {}
extension Map: MapSource {}
