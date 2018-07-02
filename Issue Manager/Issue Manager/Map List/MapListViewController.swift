// Created by Julian Dunskus

import UIKit

class MapListViewController: UITableViewController {
	var building: Building! {
		didSet {
			navigationItem.title = building?.name
			reload()
		}
	}
	var maps: [Map] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}
	
	func reload() {
		maps = building.childMaps().sorted { $0.name < $1.name }
		tableView.reloadData()
	}
	
	// MARK: - Segues
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail", let indexPath = tableView.indexPathForSelectedRow {
			let map = maps[indexPath.row]
			let destinationNav = segue.destination as! UINavigationController
			let controller = destinationNav.topViewController as! MapViewController
			controller.map = map
			controller.loadViewIfNeeded()
			// `controller` isn't in `splitViewController` yet, so we have to do it from here
			controller.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem
			splitViewController?.toggleMasterView()
		}
	}
	
	// MARK: - Table View
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return maps.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeue(MapCell.self, for: indexPath)!
		cell.map = maps[indexPath.row]
		return cell
	}
}
