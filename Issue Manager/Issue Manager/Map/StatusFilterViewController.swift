// Created by Julian Dunskus

import UIKit

class StatusFilterViewController: UITableViewController {
	typealias Localization = L10n.Map.StatusFilter
	typealias Status = Issue.Status.Simplified
	
	var delegate: StatusFilterViewControllerDelegate?
	var selected: Set<Status>!
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return Status.allCases.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Status", for: indexPath)
		let status = Status.allCases[indexPath.row]
		
		cell.textLabel!.text = status.localizedName.capitalized
		cell.accessoryType = selected.contains(status) ? .checkmark : .none
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch selected.count {
		case Status.allCases.count:
			return Localization.allSelected
		case 0:
			return Localization.noneSelected
		default:
			return Localization.someSelected
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let status = Status.allCases[indexPath.row]
		
		selected.formSymmetricDifference([status])
		tableView.reloadData()
		
		delegate?.statusFilterChanged(to: selected)
	}
}

extension Issue.Status.Simplified {
	typealias Localization = L10n.Issue.Status
	
	var localizedName: String {
		switch self {
		case .new:
			return Localization.new
		case .registered:
			return Localization.registered
		case .responded:
			return Localization.responded
		case .reviewed:
			return Localization.reviewed
		}
	}
}

protocol StatusFilterViewControllerDelegate {
	func statusFilterChanged(to newValue: Set<Issue.Status.Simplified>)
}
