// Created by Julian Dunskus

import UIKit

class MapListViewController: UITableViewController, LoadedViewController {
	typealias Localization = L10n.MapList
	
	static let storyboardID = "Map List"
	
	@IBOutlet var backToBuildingsButton: UIBarButtonItem!
	
	var holder: MapHolder! {
		didSet {
			navigationItem.title = holder.name
			
			maps = holder.childMaps().sorted { $0.name < $1.name }
		}
	}
	
	var maps: [Map] = [] {
		didSet {
			tableView.reloadData()
		}
	}
	
	var mainController: MainViewController {
		return splitViewController as! MainViewController
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		clearsSelectionOnViewWillAppear = false
	}
	
	override func viewWillAppear(_ animated: Bool) {
		if let selected = tableView.indexPathForSelectedRow {
			if !mainController.isCollapsed {
				// deselect map unless currently shown
				let mapController = mainController.detailNav.mapController
				let currentMap = mapController.holder
				if map(for: selected).id != currentMap?.id {
					tableView.deselectRow(at: selected, animated: true)
				} else if !map(for: selected).children.isEmpty {
					// must have navigated back from map's sublist
					showOwnMap()
				}
			} else {
				// compact; always deselect
				tableView.deselectRow(at: selected, animated: true)
			}
		} else if !mainController.isCollapsed {
			showOwnMap()
		}
		
		navigationItem.leftBarButtonItem = holder is Building ? backToBuildingsButton : nil
		
		super.viewWillAppear(animated)
	}
	
	func showOwnMap() {
		// update shown map
		if !mainController.isCollapsed {
			let mapController = mainController.detailNav.mapController
			if holder is Map {
				tableView.selectRow(at: [0, 0], animated: false, scrollPosition: .none)
			} else if let selected = tableView.indexPathForSelectedRow {
				tableView.deselectRow(at: selected, animated: true)
			}
			
			if holder.id != mapController.holder?.id {
				mapController.holder = holder
			}
		} else {
			showMapController(for: holder)
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
	
	func map(for indexPath: IndexPath) -> Map {
		if indexPath.section == 0, let map = holder as? Map {
			return map
		} else {
			return maps[indexPath.row]
		}
	}
	
	// MARK: - Table View
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return holder is Map ? 2 : 1
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if holder is Map {
			return [Localization.Section.thisMap, Localization.Section.childMaps][section]
		} else {
			return Localization.Section.childMaps
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if holder is Map {
			return [1, maps.count][section]
		} else {
			return maps.count
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return tableView.dequeue(MapCell.self, for: indexPath)! <- {
			if indexPath.section == 0, holder is Map {
				$0.shouldUseRecursiveIssues = false
			}
			$0.map = map(for: indexPath)
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if indexPath == tableView.indexPathForSelectedRow {
			// already selected
			return nil
		} else {
			return indexPath
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0, holder is Map {
			showOwnMap()
		} else {
			let map = maps[indexPath.row]
			
			if !mainController.isCollapsed {
				let mapController = mainController.detailNav.mapController
				mapController.holder = map
				
				if !map.children.isEmpty {
					showListController(for: map)
				}
			} else {
				if map.children.isEmpty {
					showMapController(for: map)
				} else {
					showListController(for: map)
				}
			}
		}
	}
}
