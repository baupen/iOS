// Created by Julian Dunskus

import UIKit
import SwiftUI
import class Combine.AnyCancellable

final class SiteListViewController: RefreshingTableViewController, InstantiableViewController {
	fileprivate typealias Localization = L10n.SiteList
	
	static let storyboardName = "Site List"
	
	@IBOutlet private var welcomeLabel: UILabel!
	
	@IBOutlet private var siteListView: UICollectionView!
	@IBOutlet private var refreshHintLabel: UILabel!
	
	@IBOutlet private var clientModeCell: UITableViewCell!
	@IBOutlet private var clientModeSwitch: UISwitch!
	
	@IBOutlet private var fileProgressBar: UIProgressView!
	@IBOutlet private var fileProgressLabel: UILabel!
	
	@IBAction func clientModeSwitched() {
		ViewOptions.shared.isInClientMode = clientModeSwitch.isOn
	}
	
	@IBAction func backToSiteList(_ segue: UIStoryboardSegue) {
		updateContent()
	}
	
	@IBAction func manageStorage() {
		let controller = UIHostingController(rootView: StorageSpaceView())
		present(controller, animated: true)
	}
	
	private var fileDownloadProgress = FileDownloadProgress.done {
		didSet {
			switch fileDownloadProgress {
			case .undetermined:
				fileProgressBar.progress = 0
				fileProgressLabel.text = Localization.FileProgress.indeterminate
			case .determined(let current, let total):
				fileProgressBar.progress = Float(current) / Float(total)
				fileProgressLabel.text = Localization.FileProgress.determinate(current, total)
			case .done:
				break
			}
			
			if (fileDownloadProgress == .done) != (oldValue == .done) {
				tableView.reloadData()
			}
		}
	}
	
	override var isRefreshing: Bool {
		didSet {
			siteListView.visibleCells
				.forEach { ($0 as! SiteCell).isRefreshing = isRefreshing }
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
	
	private var viewOptionsToken: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let user = client.localUser!
		welcomeLabel.text = Localization.welcome(user.givenName ?? "")
		
		updateClientModeAppearance()
		viewOptionsToken = ViewOptions.shared.didChange.sink { [unowned self] in
			updateClientModeAppearance()
			siteListView.reloadData()
		}
		
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
		Task {
			if self.needsRefresh, self.presentedViewController == nil {
				self.needsRefresh = false
				self.refreshManually()
			}
		}
	}
	
	override func doRefresh() async throws {
		try await syncManager.withContext { 
			try await $0
				.onProgress(.onMainActor { self.syncProgress = $0 })
				.onIssueImageProgress(.onMainActor { self.fileDownloadProgress = $0 })
				.pullRemoteChanges()
		}
		
		updateContent()
	}
	
	private func updateContent() {
		sites = repository.read(ConstructionSite.all().withoutDeleted.fetchAll) // TODO: order?
		siteListView.reloadData()
	}
	
	func updateClientModeAppearance() {
		clientModeSwitch.isOn = Issue.isInClientMode
		let color = Issue.isInClientMode ? UIColor.clientMode : nil
		UIView.animate(withDuration: 0.1) {
			self.clientModeCell.backgroundColor = color
		}
	}
	
	func showMapList(for site: ConstructionSite, animated: Bool = true) {
		let main = MainViewController.instantiate()!
		main.site = site
		
		present(main, animated: animated)
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		UITableView.automaticDimension
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		4 + (fileDownloadProgress == .done ? 0 : 1)
	}
}

extension SiteListViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		sites.count
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
