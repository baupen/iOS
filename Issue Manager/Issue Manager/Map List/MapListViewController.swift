// Created by Julian Dunskus

import UIKit

class MapListViewController: UITableViewController {
	var source: MapSource! {
		didSet {
			navigationItem.title = source.name
			reload()
		}
	}
	
	var maps: [Map] = []
	
	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}
	
	func reload() {
		maps = source.childMaps().sorted { $0.name < $1.name }
		tableView.reloadData()
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
			// TODO reevaluate
			// mapController isn't in splitViewController yet, so we have to do it from here
			//mapController.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem
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
}

extension Building: MapSource {}
extension Map: MapSource {}
