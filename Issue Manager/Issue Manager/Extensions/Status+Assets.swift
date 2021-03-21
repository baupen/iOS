// Created by Julian Dunskus

import UIKit

extension Issue.Status.Simplified {
	typealias Localization = L10n.Issue.Status
	
	var localizedName: String {
		switch self {
		case .new:
			return Localization.new
		case .registered:
			return Localization.registered
		case .resolved:
			return Localization.resolved
		case .closed:
			return Localization.closed
		}
	}
	
	var shadedIcon: UIImage {
		switch self {
		case .new:
			return #imageLiteral(resourceName: "issue_new.pdf") 
		case .registered:
			return #imageLiteral(resourceName: "issue_created.pdf")
		case .resolved:
			return #imageLiteral(resourceName: "issue_responded.pdf")
		case .closed:
			return #imageLiteral(resourceName: "issue_reviewed.pdf")
		}
	}
	
	var flatIcon: UIImage {
		switch self {
		case .new:
			return #imageLiteral(resourceName: "flat_issue_new.pdf") 
		case .registered:
			return #imageLiteral(resourceName: "flat_issue_created.pdf")
		case .resolved:
			return #imageLiteral(resourceName: "flat_issue_responded.pdf")
		case .closed:
			return #imageLiteral(resourceName: "flat_issue_reviewed.pdf")
		}
	}
}

extension Issue.Status {
	typealias Localization = L10n.Issue.Status
	
	func makeLocalizedMultilineDescription() -> String {
		guard let registeredBy = registeredBy else {
			return Localization.new
		}
		
		let name = Repository.shared.object(registeredBy)?.fullName ?? Localization.unknownEntity
		var description = Localization.registeredBy(name)
		
		if let resolvedBy = resolvedBy {
			let name = Repository.shared.object(resolvedBy)?.company ?? Localization.unknownEntity
			description += "\n"
			description += Localization.resolvedBy(name)
		}
		
		if let closedBy = closedBy {
			let name = Repository.shared.object(closedBy)?.fullName ?? Localization.unknownEntity
			description += "\n"
			description += Localization.closedBy(name)
		}
		
		return description
	}
}
