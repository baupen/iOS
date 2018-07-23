// Created by Julian Dunskus

import UIKit

class TradeSelectionHandler: SimpleSelectionHandler {
	typealias Localization = L10n.ViewIssue.SelectTrade
	typealias Cell = TradeCell
	typealias EmptyCell = NoTradeCell
	
	let title = Localization.title
	
	var items: [String]
	var currentItem: String?
	var selectionCallback: (String?) -> Void
	
	init(in building: Building, currentTrade: String?, callback: @escaping SelectionCallback) {
		self.items = building.allTrades().sorted()
		self.currentItem = currentTrade
		self.selectionCallback = callback
	}
	
	func configure(_ cell: Cell, for trade: String) {
		cell.nameLabel.text = trade
	}
}

class NoTradeCell: UITableViewCell, LoadedTableCell {
	static let reuseID = "No Trade Cell"
}

class TradeCell: UITableViewCell, LoadedTableCell {
	static let reuseID = "Trade Cell"
	
	@IBOutlet var nameLabel: UILabel!
}

class CraftsmanSelectionHandler: SimpleSelectionHandler {
	typealias Localization = L10n.ViewIssue.SelectCraftsman
	typealias Cell = CraftsmanCell
	typealias EmptyCell = NoCraftsmanCell
	
	var items: [Craftsman]
	var currentItem: Craftsman?
	var selectionCallback: (Craftsman?) -> Void
	var trade: String?
	
	var title: String {
		return trade ?? Localization.title
	}
	
	init(options: [Craftsman], trade: String?, current: Craftsman?, callback: @escaping SelectionCallback) {
		self.trade = trade
		self.items = options
		self.currentItem = current
		self.selectionCallback = callback
	}
	
	func configure(_ cell: Cell, for craftsman: Craftsman) {
		cell.nameLabel.text = craftsman.name
		cell.tradeLabel.text = craftsman.trade
		cell.tradeLabel.isHidden = trade != nil // all the same trade anyway
	}
}

class NoCraftsmanCell: UITableViewCell, LoadedTableCell {
	static let reuseID = "No Craftsman Cell"
}

class CraftsmanCell: UITableViewCell, LoadedTableCell {
	static let reuseID = "Craftsman Cell"
	
	@IBOutlet var nameLabel: UILabel!
	@IBOutlet var tradeLabel: UILabel!
}
