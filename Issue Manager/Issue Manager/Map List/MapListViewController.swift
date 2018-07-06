// Created by Julian Dunskus

import UIKit

class MapListViewController: UITableViewController, LoadedViewController {
	static let storyboardID = "Map List"
	
	@IBOutlet var backToBuildingsButton: UIBarButtonItem!
	@IBOutlet var showMapButton: UIBarButtonItem!
	
	@IBAction func showMap(_ sender: Any) {
		showMapController(for: holder)
	}
	
	var holder: MapHolder! {
		didSet {
			navigationItem.title = holder.name
			updateShowMapButton()
			
			maps = holder.childMaps().sorted { $0.name < $1.name }
		}
	}
	
	var maps: [Map] = [] {
		didSet {
			tableView.reloadData()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = clearsSelectionOnViewWillAppear || splitViewController!.isCollapsed
		updateShowMapButton()
		
		let isRoot = holder is Building
		navigationItem.leftBarButtonItem = isRoot ? backToBuildingsButton : nil
		
		super.viewWillAppear(animated)
	}
	
	func updateShowMapButton() {
		showMapButton.isEnabled = holder.filename != nil
		
		if let splitViewController = splitViewController {
			let isMapShown = splitViewController.viewControllers.count == 2
			navigationItem.rightBarButtonItem = isMapShown ? nil : showMapButton
		}
	}
	
	func showMapController(for holder: MapHolder) {
		let mapController = storyboard!.instantiate(MapViewController.self)!
		mapController.holder = holder
		show(mapController, sender: self)
	}
	
	func showListController(for holder: MapHolder) {
		let listController = storyboard!.instantiate(MapListViewController.self)!
		listController.holder = holder
		show(listController, sender: self)
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
		
		clearsSelectionOnViewWillAppear = !map.children.isEmpty
		
		if mainController.isCollapsed {
			if map.children.isEmpty {
				showMapController(for: map)
			} else {
				showListController(for: map)
			}
		} else {
			let mapController = mainController.detailNav!.topViewController as! MapViewController
			mapController.holder = map
			
			if !map.children.isEmpty {
				showListController(for: map)
			}
		}
	}
}
