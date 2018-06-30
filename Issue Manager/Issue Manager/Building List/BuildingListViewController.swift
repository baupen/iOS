// Created by Julian Dunskus

import UIKit

class BuildingListViewController: UITableViewController, LoadedViewController {
	fileprivate typealias Localization = L10n.BuildingList
	
	static let storyboardID = "Building List"
	
	@IBOutlet var welcomeLabel: UILabel!
	@IBOutlet var clientModeSwitch: UISwitch!
	@IBOutlet var clientModeCell: UITableViewCell!
	@IBOutlet var buildingListView: UICollectionView!
	
	@IBAction func clientModeSwitched() {
		Client.shared.isInClientMode = clientModeSwitch.isOn
		Client.shared.saveShared()
		updateClientModeAppearance()
	}
	
	@objc func refresh(_ refresher: UIRefreshControl) {
		isRefreshing = true
		buildingListView.reloadData()
		
		let result = Client.shared.read()
		
		result.then {
			self.buildings = Array(Client.shared.storage.buildings.values)
		}
		result.always {
			DispatchQueue.main.async {
				refresher.endRefreshing()
				self.isRefreshing = false
				self.buildingListView.reloadData()
			}
		}
		result.catch { error in
			DispatchQueue.main.async {
				switch error {
				case RequestError.communicationError:
					self.showAlert(titled: L10n.Alert.ConnectionIssues.title,
								   message: L10n.Alert.ConnectionIssues.message)
				default:
					self.showAlert(titled: L10n.Alert.UnknownSyncError.title,
								   message: L10n.Alert.UnknownSyncError.message)
				}
			}
		}
	}
	
	var isRefreshing = false
	var buildings: [Building] = [] {
		didSet {
			buildings += buildings // TODO remove after testing
			buildings.sort {
				$0.name < $1.name // TODO use last opened date instead
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let user = Client.shared.user!
		welcomeLabel.text = Localization.welcome(user.givenName)
		
		clientModeSwitch.isOn = Client.shared.isInClientMode
		updateClientModeAppearance()
		
		buildings = Array(Client.shared.storage.buildings.values)
		
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
		tableView.refreshControl = refreshControl
	}
	
	func updateClientModeAppearance() {
		clientModeCell.backgroundColor = Client.shared.backgroundColor
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
	
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return 100
	}
}

extension BuildingListViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return isRefreshing ? 0 : buildings.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeue(BuildingCell.self, for: indexPath)!
		
		let building = buildings[indexPath.item]
		cell.building = building
		
		return cell
	}
}

extension BuildingListViewController: UICollectionViewDelegateFlowLayout {}

class BuildingLayout: UICollectionViewFlowLayout {
	override func prepare() {
		super.prepare()
		
		guard let collectionView = collectionView else { return }
		
		let size = collectionView.bounds.size
		let inset = sectionInset
		itemSize = size - CGSize(width: inset.left + inset.right, height: inset.top + inset.bottom)
	}
	
	// snaps cells to bounds; relies on the layout being a single horizontally scrolling list
	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
		guard proposedContentOffset.x > 0 else { return proposedContentOffset }
		
		let offset = minimumLineSpacing / 2
		let lineDistance = itemSize.width + minimumLineSpacing
		let offsetWithinCell = proposedContentOffset.x.truncatingRemainder(dividingBy: lineDistance) - offset
		let rounded = (offsetWithinCell / lineDistance).rounded() * lineDistance
		let offsetWithinView = (proposedContentOffset.x / lineDistance).rounded(.down) * lineDistance
		let targetOffset = offsetWithinView + rounded
		return CGPoint(x: targetOffset, y: proposedContentOffset.y)
	}
	
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		return true
	}
}

extension Client {
	var backgroundColor: UIColor {
		return isInClientMode ? #colorLiteral(red: 1, green: 0.945, blue: 0.9, alpha: 1) : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	}
}
