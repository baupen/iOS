// Created by Julian Dunskus

import UIKit

final class SiteListViewController: RefreshingTableViewController, Reusable {
	fileprivate typealias Localization = L10n.SiteList
	
	@IBOutlet var welcomeLabel: UILabel!
	@IBOutlet var clientModeSwitch: UISwitch!
	@IBOutlet var clientModeCell: UITableViewCell!
	@IBOutlet var siteListView: UICollectionView!
	@IBOutlet var refreshHintLabel: UILabel!
	
	@IBAction func clientModeSwitched() {
		defaults.isInClientMode = clientModeSwitch.isOn
		updateClientModeAppearance()
		siteListView.reloadData()
	}
	
	@IBAction func backToSiteList(_ segue: UIStoryboardSegue) {
		updateContent()
	}
	
	override var isRefreshing: Bool {
		didSet {
			siteListView.visibleCells.forEach { ($0 as! SiteCell).isRefreshing = isRefreshing }
		}
	}
	
	private var sites: [ConstructionSite] = [] {
		didSet {
			sites.sort {
				$0.name < $1.name // TODO: use last opened date instead
			}
			refreshHintLabel.isHidden = !sites.isEmpty
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let user = Client.shared.localUser!.user
		welcomeLabel.text = Localization.welcome(user.givenName)
		
		clientModeSwitch.isOn = defaults.isInClientMode
		updateClientModeAppearance()
		
		updateContent()
	}
	
	var needsRefresh = false
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		needsRefresh = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// have to wait because we're not presenting anything yet
		DispatchQueue.main.async {
			if self.needsRefresh {
				self.needsRefresh = false
				self.refreshManually()
			}
		}
	}
	
	override func refreshCompleted() {
		super.refreshCompleted()
		
		updateContent()
	}
	
	private func updateContent() {
		sites = Repository.read(ConstructionSite.fetchAll) // TODO: order?
		siteListView.reloadData()
	}
	
	func updateClientModeAppearance() {
		let color = defaults.isInClientMode ? UIColor.clientMode : nil
		UIView.animate(withDuration: 0.1) {
			self.clientModeCell.backgroundColor = color
		}
		UINavigationBar.appearance().barTintColor = color
	}
	
	func showMapList(for site: ConstructionSite, animated: Bool = true) {
		let main = storyboard!.instantiate(MainViewController.self)!
		main.site = site
		
		present(main, animated: animated)
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
}

extension SiteListViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return sites.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeue(SiteCell.self, for: indexPath)!
		
		cell.site = sites[indexPath.item]
		cell.isRefreshing = isRefreshing
		
		return cell
	}
}

extension SiteListViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let site = sites[indexPath.item]
		showMapList(for: site)
	}
}
