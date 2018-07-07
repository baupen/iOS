// Created by Julian Dunskus

import UIKit

protocol LoadedViewController where Self: UIViewController {
	static var storyboardID: String { get }
}

extension UIStoryboard {
	func instantiate<Controller>(_ type: Controller.Type = Controller.self) -> Controller? where Controller: LoadedViewController {
		return instantiateViewController(withIdentifier: Controller.storyboardID) as? Controller
	}
}

protocol LoadedTableCell where Self: UITableViewCell {
	static var reuseID: String { get }
}

extension UITableView {
	func dequeue<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? where Cell: LoadedTableCell {
		return dequeueReusableCell(withIdentifier: Cell.reuseID, for: indexPath) as? Cell
	}
}

protocol LoadedCollectionCell where Self: UICollectionViewCell {
	static var reuseID: String { get }
}

extension UICollectionView {
	func dequeue<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? where Cell: LoadedCollectionCell {
		return dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as? Cell
	}
}
