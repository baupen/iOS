// Created by Julian Dunskus

import UIKit
import HandyOperators

fileprivate let rowHeight: CGFloat = 37

fileprivate typealias SuggestionMatch = (suggestion: Suggestion, matchingPrefix: String?)

@MainActor
final class SuggestionsHandler: NSObject, UITableViewDataSource, UITableViewDelegate {
	static let intrinsicHeight = CGFloat(suggestionCount) * rowHeight - 1
	static let suggestionCount = 3
	
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
	
	private var matches: [SuggestionMatch] = [] {
		didSet {
			tableView.isHidden = matches.isEmpty
			tableView.reloadData()
		}
	}
	
	private static let taskManager = TaskManager<Void, Never>()
	
	func update() {
		guard tableView != nil else { return }
		
		let trade = self.trade
		let prefix = self.currentDescription?.nonEmptyOptional
		
		Task {
			await Self.taskManager.runIfNewest {
				let suggestions = await Task.detached(priority: .userInitiated) {
					await SuggestionStorage.shared.suggestions(
						forTrade: trade,
						matching: prefix,
						count: SuggestionsHandler.suggestionCount
					)
				}.value
				self.matches = suggestions.map { ($0, prefix) }
			}
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		min(SuggestionsHandler.suggestionCount, matches.count)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		tableView.dequeue(SuggestionCell.self, for: indexPath)! <- {
			$0.match = matches[indexPath.row]
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		rowHeight
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		delegate?.use(matches[indexPath.row].suggestion)
	}
}

@MainActor
protocol SuggestionsHandlerDelegate: AnyObject {
	func use(_ suggestion: Suggestion)
}

final class SuggestionCell: UITableViewCell, Reusable {
	@IBOutlet private var suggestionLabel: UILabel!
	
	fileprivate var match: SuggestionMatch! {
		didSet {
			if let prefix = match.matchingPrefix {
				let text = NSMutableAttributedString(string: match.suggestion.text)
				let matchingRange = NSRange(location: 0, length: prefix.count)
				text.addAttributes(
					[
						.backgroundColor: #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 0.2),
						.underlineStyle: NSUnderlineStyle.single.rawValue,
						.underlineColor: #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 0.5)
					],
					range: matchingRange
				)
				suggestionLabel.attributedText = text
			} else {
				suggestionLabel.text = match.suggestion.text
			}
		}
	}
}
