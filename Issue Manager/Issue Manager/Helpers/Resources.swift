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
		case .responded:
			return Localization.responded
		case .reviewed:
			return Localization.reviewed
		}
	}
	
	var shadedIcon: UIImage {
		switch self {
		case .new:
			return #imageLiteral(resourceName: "issue_new.pdf") 
		case .registered:
			return #imageLiteral(resourceName: "issue_created.pdf")
		case .responded:
			return #imageLiteral(resourceName: "issue_responded.pdf")
		case .reviewed:
			return #imageLiteral(resourceName: "issue_reviewed.pdf")
		}
	}
	
	var flatIcon: UIImage {
		switch self {
		case .new:
			return #imageLiteral(resourceName: "flat_issue_new.pdf") 
		case .registered:
			return #imageLiteral(resourceName: "flat_issue_created.pdf")
		case .responded:
			return #imageLiteral(resourceName: "flat_issue_responded.pdf")
		case .reviewed:
			return #imageLiteral(resourceName: "flat_issue_reviewed.pdf")
		}
	}
}

extension Issue.Status {
	typealias Localization = L10n.Issue.Status
	
	var localizedMultilineDescription: String {
		guard let registration = registration else {
			return Localization.new
		}
		
		var description = Localization.registeredBy(registration.author)
		
		if let response = response {
			description += "\n"
			description += Localization.respondedBy(response.author)
		}
		
		if let review = review {
			description += "\n"
			description += Localization.reviewedBy(review.author)
		}
		
		return description
	}
}
