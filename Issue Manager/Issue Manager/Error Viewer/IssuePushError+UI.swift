// Created by Julian Dunskus

import Foundation
import HandyOperators

extension IssuePushError {
	func discardChanges() {
		switch (stage, issue.wasUploaded) {
		case (.patch, true): // could not patch an existing issue
			Repository.shared.save(issue <- { $0.discardChangePatch() })
		case (.deletion, true): // could not delete an uploaded issue
			Repository.shared.save(issue <- { $0.undelete() })
		case
			(.patch, false), // could not upload a freshly-created issue
			(.deletion, false): // could not delete a freshly-created issue
			Repository.shared.remove(issue) // simply discard the new issue
		case (.imageUpload, _): // could not upload an image for an issue
			Repository.shared.save(issue <- { $0.didChangeImage = false })
		}
	}
	
	var quickIssueIdentifier: String {
		[String].init {
			stageDescription
			
			issue.number.map { "#\($0)" }
			
			if let description = issue.description?.nonEmptyOptional {
				let maxDescLength = 50
				if description.count <= maxDescLength {
					description
				} else {
					String(description.prefix(maxDescLength))
				}
			}
		}.joined(separator: " – ")
	}
	
	var stageDescription: String {
		stage.description(wasUploaded: issue.wasUploaded)
	}
}

extension IssuePushError.Stage {
	func description(wasUploaded: Bool) -> String {
		typealias L = L10n.ErrorViewer.PushFailed.Stage
		switch self {
		case .patch:
			return wasUploaded ? L.patch : L.create
		case .imageUpload:
			return L.imageUpload
		case .deletion:
			return L.deletion
		}
	}
}
