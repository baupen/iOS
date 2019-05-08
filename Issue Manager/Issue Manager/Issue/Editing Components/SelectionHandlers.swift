// Created by Julian Dunskus

import UIKit

final class TradeSelectionHandler: SimpleSelectionHandler {
	typealias Localization = L10n.ViewIssue.SelectTrade
	typealias Cell = TradeCell
	typealias EmptyCell = NoTradeCell
	
	let title = Localization.title
	
	var items: [String]
	var currentItem: String?
	var selectionCallback: (String?) -> Void
	
	init(in site: ConstructionSite, currentTrade: String?, callback: @escaping SelectionCallback) {
		self.items = Repository.read(site.trades
			.order(Craftsman.Columns.trade.asc)
			.fetchAll
		)
		self.currentItem = currentTrade
		self.selectionCallback = callback
	}
	
	func configure(_ cell: Cell, for trade: String) {
		cell.nameLabel.text = trade
	}
}

final class NoTradeCell: UITableViewCell, Reusable {}

final class TradeCell: UITableViewCell, Reusable {
	@IBOutlet var nameLabel: UILabel!
}

final class CraftsmanSelectionHandler: SimpleSelectionHandler {
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

final class NoCraftsmanCell: UITableViewCell, Reusable {}

final class CraftsmanCell: UITableViewCell, Reusable {
	@IBOutlet var nameLabel: UILabel!
	@IBOutlet var tradeLabel: UILabel!
}
