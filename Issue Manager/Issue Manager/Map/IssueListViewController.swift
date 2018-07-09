// Created by Julian Dunskus

import UIKit
import PullToExpand

class IssueListViewController: UIViewController {
	typealias Localization = L10n.Map.IssueList
	
	@IBOutlet var summaryLabel: UILabel!
	@IBOutlet var separatorView: UIView!
	@IBOutlet var issueTableView: UITableView!
	@IBOutlet var separatorHeightConstraint: NSLayoutConstraint!
	
	var pullableView: PullableView!
	
	var map: Map? {
		didSet {
			update()
		}
	}
	
	var issues: [Issue] = [] {
		didSet {
			issueTableView.reloadData()
		}
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
		
		issues = Array(map.allIssues())
		let openIssues = issues.lazy.filter { !$0.isReviewed }.count
		summaryLabel.text = Localization.summary(String(openIssues), String(issues.count))
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
		}
	}
}

extension IssueListViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return issues.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeue(IssueCell.self, for: indexPath)!
		cell.issue = issues[indexPath.row]
		return cell
	}
}

extension IssueListViewController: UITableViewDelegate {}
