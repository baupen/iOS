// Created by Julian Dunskus

import UIKit

final class SelectionViewController: UIViewController {
	@IBOutlet private var tableView: UITableView!
	
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

final class SelectionHandler<Handler: SimpleSelectionHandler>: NSObject, AnySelectionHandler {
	private var handler: Handler
	private unowned var viewController: UIViewController!
	
	var title: String {
		handler.title
	}
	
	init(wrapping handler: Handler) {
		self.handler = handler
	}
	
	func prepare(_ tableView: UITableView, in controller: UIViewController) {
		self.viewController = controller
		if let current = handler.currentItem, let index = handler.items.firstIndex(of: current) {
			tableView.selectRow(at: [1, index], animated: true, scrollPosition: .middle)
		} else {
			tableView.selectRow(at: [0, 0], animated: true, scrollPosition: .none)
		}
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		2
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		section == 0 ? 1 : handler.items.count
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
		UITableView.automaticDimension
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		handler.selectionCallback(indexPath.section == 0 ? nil : handler.items[indexPath.row])
		viewController.navigationController!.popViewController(animated: true)
	}
}

protocol SimpleSelectionHandler: AnyObject {
	associatedtype Item: Equatable
	associatedtype Cell: UITableViewCell, Reusable
	associatedtype EmptyCell: UITableViewCell, Reusable
	
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
		SelectionHandler(wrapping: self)
	}
}
