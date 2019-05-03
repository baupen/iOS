// Created by Julian Dunskus

import UIKit

final class MapListViewController: RefreshingTableViewController, Reusable {
	typealias Localization = L10n.MapList
	
	@IBOutlet var backToSiteListButton: UIBarButtonItem!
	
	var holder: MapHolder! {
		didSet { update() }
	}
	
	private var maps: [Map]! {
		didSet { tableView.reloadData() }
	}
	
	private var mainController: MainViewController {
		return splitViewController as! MainViewController
	}
	
	override var isRefreshing: Bool {
		didSet {
			tableView.visibleCells.forEach { ($0 as! MapCell).isRefreshing = isRefreshing }
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		clearsSelectionOnViewWillAppear = false
		
		update()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		if mainController.isCollapsed {
			if let selected = tableView.indexPathForSelectedRow {
				// coming back from selected map's sublist
				tableView.deselectRow(at: selected, animated: true)
			}
		} else if let selected = tableView.indexPathForSelectedRow {
			// not appearing for the first time
			if Repository.shared.hasChildren(for: map(for: selected)) {
				// coming back from selected map's sublist
				showOwnMap()
			} else {
				// appearing because split view was expanded to show list
			}
		} else {
			// appearing for the first time
			showOwnMap()
		}
		
		navigationItem.leftBarButtonItem = holder is ConstructionSite ? backToSiteListButton : nil
		
		super.viewWillAppear(animated)
	}
	
	override func refreshCompleted() {
		super.refreshCompleted()
		
		let isValid = handleRefresh()
		if isValid {
			if mainController.isExtended {
				mainController.detailNav.mapController.holder = holder
			}
		} else {
			showAlert(
				titled: Localization.MapRemoved.title,
				message: Localization.MapRemoved.message
			) {
				self.performSegue(withIdentifier: "back to site list", sender: self)
			}
		}
		
		for viewController in navigationController!.viewControllers where viewController !== self {
			(viewController as? MapListViewController)?.handleRefresh()
		}
	}
	
	/// - returns: whether or not the holder is still valid
	@discardableResult private func handleRefresh() -> Bool {
		if let oldSite = holder as? ConstructionSite, let site = Repository.shared.site(oldSite.id) {
			holder = site
			return true
		} else if let oldMap = holder as? Map, let map = Repository.shared.map(oldMap.id) {
			holder = map
			return true
		} else {
			maps = []
			return false
		}
	}
	
	func update() {
		guard isViewLoaded, let holder = holder else { return }
		
		navigationItem.title = holder.name
		
		maps = Repository.shared.children(of: holder).sorted { $0.name < $1.name }
	}
	
	func showOwnMap() {
		// update shown map
		if mainController.isExtended {
			let mapController = mainController.detailNav.mapController
			if holder is Map {
				tableView.selectRow(at: [0, 0], animated: false, scrollPosition: .none)
			} else if let selected = tableView.indexPathForSelectedRow {
				tableView.deselectRow(at: selected, animated: true)
			}
			
			if holder.rawID != mapController.holder?.rawID {
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
	
	/// reloads the cell for the given map, if currently visible
	func reload(_ map: Map) {
		guard holder.rawID == map.rawID || holder.rawID == map.parentHolderID else { return }
		for cell in tableView.visibleCells {
			let mapCell = cell as! MapCell
			if mapCell.map.id == map.id {
				mapCell.update()
			}
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
			$0.isRefreshing = isRefreshing
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
			
			if mainController.isExtended {
				let mapController = mainController.detailNav.mapController
				mapController.holder = map
				
				if map.hasChildren {
					showListController(for: map)
				}
			} else {
				if map.hasChildren {
					showListController(for: map)
				} else {
					showMapController(for: map)
				}
			}
		}
	}
}
