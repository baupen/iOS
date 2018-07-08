// Created by Julian Dunskus

import UIKit

fileprivate let refreshingCellAlpha: CGFloat = 0.25

class BuildingListViewController: UITableViewController, LoadedViewController {
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
	}
	
	// unwind segue
	@IBAction func backToBuildingList(_ segue: UIStoryboardSegue) {}
	
	@objc func refresh(_ refresher: UIRefreshControl) {
		isRefreshing = true
		buildingListView.visibleCells.forEach { ($0 as! BuildingCell).isRefreshing = true }
		
		let result = Client.shared.read().on(.main)
		
		result.always {
			refresher.endRefreshing()
			self.isRefreshing = false
		}
		result.then {
			self.buildings = Array(Client.shared.storage.buildings.values)
			self.buildingListView.reloadData()
		}
		result.catch { error in
			typealias Alert = L10n.Alert
			switch error {
			case RequestError.communicationError:
				self.showAlert(titled: Alert.ConnectionIssues.title,
							   message: Alert.ConnectionIssues.message)
			case RequestError.apiError(let failure) where failure.error == .invalidToken:
				self.showAlert(
					titled: Alert.InvalidSession.title,
					message: Alert.InvalidSession.message
				) {
					self.dismiss(animated: true)
				}
			default:
				var errorDesc = ""
				dump(error, to: &errorDesc)
				self.showAlert(titled: Alert.UnknownSyncError.title,
							   message: Alert.UnknownSyncError.message(errorDesc))
			}
		}
	}
	
	var isRefreshing = false
	var buildings: [Building] = [] {
		didSet {
			buildings.sort {
				$0.name < $1.name // TODO use last opened date instead
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
		
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
		tableView.refreshControl = refreshControl
		
		if let id = defaults.lastBuildingID, let lastBuilding = Client.shared.storage.buildings[id] {
			DispatchQueue.main.async {
				self.showMapList(for: lastBuilding, animated: false)
			}
		}
	}
	
	func updateClientModeAppearance() {
		let color = defaults.isInClientMode ? UIColor.clientMode : nil
		UIView.animate(withDuration: 0.1) {
			self.clientModeCell.backgroundColor = color
		}
		UINavigationBar.appearance().barTintColor = color
	}
	
	func showMapList(for building: Building, animated: Bool = true) {
		defaults.lastBuildingID = building.id
		
		let main = storyboard!.instantiate(MainViewController.self)!
		main.building = building
		
		present(main, animated: animated)
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
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
