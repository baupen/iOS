// Created by Julian Dunskus

import UIKit

protocol Reusable {
	static var reuseID: String { get }
}

extension Reusable where Self: AnyObject {
	static var reuseID: String {
		return String(describing: self)
	}
}

extension UIStoryboard {
	func instantiate<Controller>(_ type: Controller.Type = Controller.self) -> Controller? where Controller: Reusable, Controller: UIViewController {
		return instantiateViewController(withIdentifier: Controller.reuseID) as? Controller
	}
}

extension UITableView {
	func dequeue<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? where Cell: Reusable, Cell: UITableViewCell {
		return dequeueReusableCell(withIdentifier: Cell.reuseID, for: indexPath) as? Cell
	}
}

extension UICollectionView {
	func dequeue<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? where Cell: Reusable, Cell: UICollectionViewCell {
		return dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as? Cell
	}
}
