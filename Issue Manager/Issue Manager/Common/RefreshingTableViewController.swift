// Created by Julian Dunskus

import UIKit

class RefreshingTableViewController: UITableViewController {
	var isRefreshing = false
	
	@objc final func refresh(_ refresher: UIRefreshControl) {
		isRefreshing = true
		
		let result = Client.shared.read().on(.main)
		
		result.always {
			refresher.endRefreshing()
			self.isRefreshing = false
		}
		result.then {
			self.refreshCompleted()
		}
		result.catch { error in
			typealias Alert = L10n.Alert
			switch error {
			case RequestError.communicationError:
				self.showAlert(
					titled: Alert.ConnectionIssues.title,
					message: Alert.ConnectionIssues.message
				)
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
				self.showAlert(
					titled: Alert.UnknownSyncError.title,
					message: Alert.UnknownSyncError.message(errorDesc)
				)
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.refreshControl = UIRefreshControl() <- {
			$0.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
		}
	}
	
	func refreshCompleted() {}
	
	func refreshManually() {
		let refresher = self.tableView.refreshControl!
		refresher.beginRefreshing()
		self.refresh(refresher)
		self.tableView.scrollRectToVisible(refresher.bounds, animated: true)
	}
}