// Created by Julian Dunskus

import UIKit
import PullToExpand

final class IssueListViewController: UIViewController {
	typealias Localization = L10n.Map.IssueList
	
	@IBOutlet var summaryLabel: UILabel!
	@IBOutlet var separatorView: UIView!
	@IBOutlet var issueTableView: UITableView!
	@IBOutlet var separatorHeightConstraint: NSLayoutConstraint!
	
	/// - note: set this _before_ the list loads its data
	weak var issueCellDelegate: IssueCellDelegate?
	
	var pullableView: PullableView! {
		didSet {
			pullableView.tapRecognizer.delegate = self
		}
	}
	
	/// set this before setting `map` initially or before loading the view to avoid calculating stuff twice
	var visibleStatuses = Issue.allStatuses {
		didSet { update() }
	}
	
	var map: Map? {
		didSet { update() }
	}
	
	private var issues: [Issue] = [] {
		didSet { issueTableView.reloadData() }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		separatorHeightConstraint.constant = 1 / UIScreen.main.scale // 1px
		separatorView.backgroundColor = issueTableView.separatorColor
		
		issueTableView.panGestureRecognizer.addTarget(self, action: #selector(listPanned))
		
		update()
	}
	
	func update() {
		guard isViewLoaded, let map = map else { return }
		
		let allIssues = Repository.read(map.sortedIssues.fetchAll)
		issues = allIssues.filter {
			visibleStatuses.contains($0.status.simplified)
		}
		
		let openCount = issues.count { $0.isOpen }
		let totalCount = allIssues.count
		if visibleStatuses == Issue.allStatuses {
			summaryLabel.text = Localization.summary(String(openCount), String(totalCount))
		} else {
			summaryLabel.text = Localization.summaryFiltered(String(issues.count), String(totalCount))
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// since this view controller is made to be embedded, we delegate all segues to the parent
		parent?.prepare(for: segue, sender: sender)
	}
	
	// MARK: PullableView-UIScrollView interaction 
	// close pullable view when scrollview is dragged down while at top
	
	private var fakePanRecognizer = FakePanRecognizer()
	private var scrollOffset: CGFloat = 0
	
	@objc func listPanned(_ recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .possible:
			break
		case .began, .changed:
			if scrollOffset + issueTableView.contentOffset.y < 0 {
				if fakePanRecognizer.state == .possible {
					scrollOffset = 0
					fakePanRecognizer.fakeTranslation = .zero
					fakePanRecognizer.state = .began
				}
				scrollOffset += issueTableView.contentOffset.y
				issueTableView.contentOffset.y = 0
				
				fakePanRecognizer.fakeTranslation.y = -scrollOffset
				pullableView.viewPulled(fakePanRecognizer)
				fakePanRecognizer.state = .changed
			} else if fakePanRecognizer.state != .possible {
				scrollOffset = 0
				fakePanRecognizer.state = .failed
				pullableView.viewPulled(fakePanRecognizer)
				fakePanRecognizer.state = .possible
			}
		case .ended, .cancelled, .failed:
			if fakePanRecognizer.state != .possible {
				scrollOffset = 0
				fakePanRecognizer.state = .ended
				pullableView.viewPulled(fakePanRecognizer)
				fakePanRecognizer.state = .possible
			}
		@unknown default:
			break
		}
	}
}

extension IssueListViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return issues.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return tableView.dequeue(IssueCell.self, for: indexPath)! <- {
			$0.delegate = issueCellDelegate
			$0.issue = issues[indexPath.row]
		}
	}
}

extension IssueListViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath == tableView.indexPathForSelectedRow || tableView.cellForRow(at: indexPath)?.isSelected == true {
			return UITableView.automaticDimension
		} else {
			return 44 // bit of a magic number but eh. also it's the recommended minimum tap target size so ¯\_(ツ)_/¯
		}
	}
	
	// Using willSelect for animations over didSelect because it allows us to do everything during the batch update, rather than having isSelected already set by the table. This makes the animations look a lot nicer. 
	
	func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		let currentSelection = tableView.indexPathForSelectedRow
		
		tableView.performBatchUpdates({
			if let previous = currentSelection {
				tableView.deselectRow(at: previous, animated: true)
			}
			
			//tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none) // using this instantly unhighlights the cell and then animates the rehighlighting during selection, which looks weird, so instead we call it in didSelect
			tableView.cellForRow(at: indexPath)?.isSelected = true
		}, completion: nil)
		
		return indexPath
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// scrolling works correctly at this point because the table now knows the cell's actual height
		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
	}
	
	func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
		tableView.performBatchUpdates({
			tableView.deselectRow(at: indexPath, animated: true)
		}, completion: nil)
		
		return indexPath
	}
}

extension IssueListViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		if let view = touch.view, view.isDescendant(of: issueTableView) {
			return false // don't interfere with taps in table
		} else {
			return true
		}
	}
}
