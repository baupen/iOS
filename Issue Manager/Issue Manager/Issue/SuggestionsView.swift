// Created by Julian Dunskus

import UIKit

fileprivate let rowHeight: CGFloat = 37

class SuggestionsHandler: NSObject, UITableViewDataSource, UITableViewDelegate {
	static let intrinsicHeight = CGFloat(suggestionCount) * rowHeight - 1
	static let suggestionCount = 5
	
	var tableView: UITableView! {
		didSet {
			tableView.dataSource = self
			tableView.delegate = self
			update()
		}
	}
	weak var delegate: SuggestionsHandlerDelegate?
	
	var trade: String? {
		didSet {
			guard trade != oldValue else { return }
			update()
		}
	}
	var currentDescription: String? {
		didSet {
			guard currentDescription != oldValue else { return }
			update()
		}
	}
	
	private var suggestions: [Suggestion] = [] {
		didSet {
			tableView.isHidden = suggestions.isEmpty
			tableView.reloadData()
		}
	}
	private var updatingQueue = DispatchQueue(label: "updating suggestions")
	
	private var currentTaskID = UUID()
	func update() {
		guard tableView != nil else { return }
		
		let taskID = UUID()
		currentTaskID = taskID
		
		let trade = self.trade
		let currentDescription = self.currentDescription
		updatingQueue.async {
			guard self.currentTaskID == taskID else { return }
			
			let suggestions = SuggestionStorage.shared.suggestions(forTrade: trade, matching: currentDescription)
			
			DispatchQueue.main.async {
				self.suggestions = suggestions
			}
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return min(SuggestionsHandler.suggestionCount, suggestions.count)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return tableView.dequeue(SuggestionCell.self, for: indexPath)! <- {
			$0.suggestion = suggestions[indexPath.row]
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return rowHeight
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		delegate?.use(suggestions[indexPath.row])
	}
}

protocol SuggestionsHandlerDelegate: AnyObject {
	func use(_ suggestion: Suggestion)
}

class SuggestionCell: UITableViewCell, LoadedTableCell {
	static let reuseID = "Suggestion Cell"
	
	@IBOutlet var suggestionLabel: UILabel!
	
	var suggestion: Suggestion! {
		didSet {
			suggestionLabel.text = suggestion.text
		}
	}
}
