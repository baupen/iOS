// Created by Julian Dunskus

import UIKit

class SelectionViewController: UIViewController {
	@IBOutlet var tableView: UITableView!
	
	var handler: AnySelectionHandler! {
		didSet { update() }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		handler.prepare(tableView, in: self)
	}
	
	func update() {
		guard isViewLoaded, let handler = handler else { return }
		
		navigationItem.title = handler.title
		tableView.delegate = handler
		tableView.dataSource = handler
	}
}

protocol AnySelectionHandler: UITableViewDelegate, UITableViewDataSource {
	var title: String { get }
	func prepare(_ tableView: UITableView, in controller: UIViewController)
}

class SelectionHandler<Handler: SimpleSelectionHandler>: NSObject, AnySelectionHandler {
	typealias Item = Handler.Item
	
	private var handler: Handler
	private var viewController: UIViewController!
	
	var title: String {
		return handler.title
	}
	
	init(wrapping handler: Handler) {
		self.handler = handler
	}
	
	func prepare(_ tableView: UITableView, in controller: UIViewController) {
		self.viewController = controller
		if let current = handler.currentItem, let index = handler.items.index(of: current) {
			tableView.selectRow(at: [1, index], animated: true, scrollPosition: .middle)
		} else {
			tableView.selectRow(at: [0, 0], animated: true, scrollPosition: .none)
		}
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? 1 : handler.items.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			return tableView.dequeue(Handler.EmptyCell.self, for: indexPath)!
		case 1:
			return tableView.dequeue(Handler.Cell.self, for: indexPath)! <- {
				handler.configure($0, for: handler.items[indexPath.row])
			}
		default:
			fatalError("unrecognized section: \(indexPath.section)")
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		handler.selectionCallback(indexPath.section == 0 ? nil : handler.items[indexPath.row])
		viewController.navigationController!.popViewController(animated: true)
	}
}

protocol SimpleSelectionHandler: AnyObject {
	associatedtype Item: Equatable
	associatedtype Cell: LoadedTableCell
	associatedtype EmptyCell: LoadedTableCell
	
	typealias SelectionCallback = (Item?) -> Void
	
	var title: String { get }
	
	var items: [Item] { get }
	var currentItem: Item? { get }
	var selectionCallback: SelectionCallback { get }
	
	func wrapped() -> AnySelectionHandler
	func configure(_ cell: Cell, for item: Item)
}

extension SimpleSelectionHandler {
	func wrapped() -> AnySelectionHandler {
		return SelectionHandler(wrapping: self)
	}
}

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
