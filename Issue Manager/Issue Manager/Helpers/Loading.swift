// Created by Julian Dunskus

import UIKit

protocol LoadedViewController {
	static var storyboardID: String { get }
}

extension UIStoryboard {
	func instantiate<Controller>(_ type: Controller.Type) -> Controller? where Controller: LoadedViewController {
		return instantiateViewController(withIdentifier: Controller.storyboardID) as? Controller
	}
}

protocol LoadedTableCell {
	static var reuseID: String { get }
}

extension UITableView {
	func dequeue<Cell>(_ type: Cell.Type) -> Cell? where Cell: LoadedTableCell {
		return dequeueReusableCell(withIdentifier: Cell.reuseID) as? Cell
	}
	
	func dequeue<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? where Cell: LoadedTableCell {
		return dequeueReusableCell(withIdentifier: Cell.reuseID, for: indexPath) as? Cell
	}
}
