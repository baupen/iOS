// Created by Julian Dunskus

import UIKit
import Promise
import ArrayBuilder

class RefreshingTableViewController: UITableViewController {
	var isRefreshing = false
	
	@objc final func refresh(_ refresher: UIRefreshControl) {
		isRefreshing = true
		
		let result = doRefresh().on(.main)
		
		result.always {
			refresher.endRefreshing()
			self.isRefreshing = false
		}
		result.then {
			self.refreshCompleted()
		}
		result.catch(showAlert)
	}
	
	func doRefresh() -> Future<Void> {
		Client.shared.pullRemoteChanges()
	}
	
	private func showAlert(for error: Error) {
		typealias Alert = L10n.Alert
		switch error {
		case RequestError.communicationError:
			self.showAlert(
				titled: Alert.ConnectionIssues.title,
				message: Alert.ConnectionIssues.message
			)
		case RequestError.notAuthenticated:
			self.showAlert(
				titled: Alert.InvalidSession.title,
				message: Alert.InvalidSession.message
			) { self.performSegue(withIdentifier: "log out", sender: self) }
		case RequestError.pushFailed(let errors):
			self.showAlert(
				// FIXME: localize
				titled: "Fehler beim Hochladen!",
				message: """
					Einige Änderungen auf dem Gerät konnten nicht erfolgreich an die Website hochgeladen werden. Dies betrifft die folgenden Pendenzen:
					
					\(errors.map(\.issueIdentifier).map { "• \($0)" }.joined(separator: "\n"))
					"""
			)
		default:
			print("refresh error!")
			dump(error)
			let errorDesc = "" <- {
				dump(error, to: &$0)
			}
			self.showAlert(
				titled: Alert.UnknownSyncError.title,
				message: Alert.UnknownSyncError.message(errorDesc)
			)
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

extension IssuePushError {
	var issueIdentifier: String {
		[String].init {
			issue.number.map { "#\($0)" }
			
			if let description = issue.description {
				let maxDescLength = 50
				if description.count <= maxDescLength {
					description
				} else {
					String(description.prefix(maxDescLength))
				}
			}
			
			issue.rawID
		}.joined(separator: " – ")
	}
	
	var quickDescription: String {
		"""
		\(issueIdentifier):
		\("" <- { dump(cause, to: &$0) })
		"""
	}
}
