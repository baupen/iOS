// Created by Julian Dunskus

import UIKit

class BuildingListViewController: RefreshingTableViewController, LoadedViewController {
	fileprivate typealias Localization = L10n.BuildingList
	
	static let storyboardID = "Building List"
	
	@IBOutlet var welcomeLabel: UILabel!
	@IBOutlet var clientModeSwitch: UISwitch!
	@IBOutlet var clientModeCell: UITableViewCell!
	@IBOutlet var buildingListView: UICollectionView!
	@IBOutlet var refreshHintLabel: UILabel!
	
	@IBAction func clientModeSwitched() {
		defaults.isInClientMode = clientModeSwitch.isOn
		updateClientModeAppearance()
		buildingListView.reloadData()
	}
	
	@IBAction func backToBuildingList(_ segue: UIStoryboardSegue) {
		buildings = Array(Client.shared.storage.buildings.values)
		buildingListView.reloadData()
	}
	
	override var isRefreshing: Bool {
		didSet {
			buildingListView.visibleCells.forEach { ($0 as! BuildingCell).isRefreshing = isRefreshing }
		}
	}
	
	private var buildings: [Building] = [] {
		didSet {
			buildings.sort {
				$0.name < $1.name // TODO: use last opened date instead
			}
			refreshHintLabel.isHidden = !buildings.isEmpty
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let user = Client.shared.user!
		welcomeLabel.text = Localization.welcome(user.givenName)
		
		clientModeSwitch.isOn = defaults.isInClientMode
		updateClientModeAppearance()
		
		buildings = Array(Client.shared.storage.buildings.values)
	}
	
	private var needsRefresh = false
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		needsRefresh = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// have to wait because we're not presenting anything yet
		DispatchQueue.main.async {
			if self.needsRefresh, self.presentedViewController == nil {
				self.refreshManually()
				self.needsRefresh = false
			}
		}
	}
	
	override func refreshCompleted() {
		super.refreshCompleted()
		
		self.buildings = Array(Client.shared.storage.buildings.values)
		self.buildingListView.reloadData()
	}
	
	func updateClientModeAppearance() {
		let color = defaults.isInClientMode ? UIColor.clientMode : nil
		UIView.animate(withDuration: 0.1) {
			self.clientModeCell.backgroundColor = color
		}
		UINavigationBar.appearance().barTintColor = color
	}
	
	func showMapList(for building: Building, animated: Bool = true) {
		let main = storyboard!.instantiate(MainViewController.self)!
		main.building = building
		
		present(main, animated: animated)
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
}

extension BuildingListViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return buildings.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeue(BuildingCell.self, for: indexPath)!
		
		let building = buildings[indexPath.item]
		cell.building = building
		cell.isRefreshing = isRefreshing
		
		return cell
	}
}

extension BuildingListViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let building = buildings[indexPath.item]
		showMapList(for: building)
	}
}
