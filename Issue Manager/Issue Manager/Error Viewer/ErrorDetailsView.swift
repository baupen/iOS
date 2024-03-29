// Created by Julian Dunskus

import SwiftUI
import HandyOperators

// this code would be a lot nicer if i could use the new SwiftUI shorthands in iOS 15+ (and 16+)

@MainActor
struct ErrorDetailsView: View {
	fileprivate typealias Localization = L10n.ErrorViewer
	
	var error: Error
	
	@Environment(\.presentationMode) @Binding private var presentationMode
	
	var body: some View {
		NavigationView {
			Form {
				switch error {
				case RequestError.pushFailed(let errors):
					FailedPushContents(errors: errors)
				case let error:
					UnknownErrorContents(error: error)
				}
			}
			.navigationTitle(Localization.title)
			.toolbar {
				ToolbarItemGroup(placement: .navigationBarLeading) {
					Button(L10n.closeSheet) {
						presentationMode.dismiss()
					}
				}
			}
		}
		.navigationViewStyle(.stack)
	}
	
	@MainActor
	struct FailedPushContents: View {
		fileprivate typealias Localization = L10n.ErrorViewer.PushFailed
		
		var errors: [IssuePushError]
		
		@State var handledErrors: Set<IssuePushError.ID> = []
		
		var body: some View {
			Section {
				Text(Localization.message)
					.font(.callout)
			}
			
			Section {
				ForEach(errors) { error in
					NavigationLink {
						PushErrorDetails(error: error) {
							handledErrors.insert(error.id)
						}
					} label: {
						VStack(alignment: .leading, spacing: 8) {
							HStack {
								Text(error.stageDescription)
									.fontWeight(.medium)
								Spacer()
								NumberLabel(number: error.issue.number)
									.opacity(0.5)
							}
							
							if let description = error.issue.description?.nonEmptyOptional {
								Text(description)
									.lineLimit(2)
									.font(.footnote)
							}
						}
						.padding(.vertical, 6)
					}
					.disabled(handledErrors.contains(error.id))
				}
			} header: {
				Text(Localization.affectedIssuesSection)
			}
			
			Section {
				let changesToDiscard = errors.count { !handledErrors.contains($0.id) }
				
				DiscardButton(
					title: Localization.MassDiscardChanges.action(changesToDiscard),
					confirmationTitle: Localization.MassDiscardChanges.confirm(changesToDiscard)
				) {
					discardAllChanges()
				}
			} header: {
				Text(L10n.ErrorViewer.actionsSection)
			}
		}
		
		func discardAllChanges() {
			for error in errors where !handledErrors.contains(error.id) {
				error.discardChanges(in: repository)
				handledErrors.insert(error.id)
			}
		}
	}
	
	struct PushErrorDetails: View {
		var error: IssuePushError
		var onDiscard: () -> Void
		
		var body: some View {
			Form {
				Section {
					HStack {
						Text(error.stageDescription)
						Spacer()
						NumberLabel(number: error.issue.number)
					}
				}
				
				Section {
					SendToDeveloperButton {
						"""
						Fehler: \(error.stageDescription)
						für \(error.issue.number.map { "Pendenz #\($0)" } ?? "neue Pendenz") (\(error.issue.rawID))

						Fehlerdetails:
						\(error.dumpedDescription())
						"""
					}
					
					DiscardButton(
						title: Localization.PushFailed.discardChanges,
						confirmationTitle: Localization.PushFailed.DiscardChanges.confirm
					) {
						error.discardChanges(in: repository)
						onDiscard()
					}
				} header: {
					Text(Localization.actionsSection)
				}
				
				Section {
					HStack {
						Text("ID:")
							.foregroundColor(.secondary)
						Spacer()
						Text(error.issue.rawID)
					}
					.font(.footnote)
					
					Text(error.dumpedDescription())
						.font(.footnote)
				} header: {
					Text(Localization.technicalDetailsSection)
				}
			}
			.navigationTitle(Localization.title) // just reuse the main title
			.navigationBarTitleDisplayMode(.inline)
		}
	}
	
	struct UnknownErrorContents: View {
		var error: Error
		
		var body: some View {
			Section {
				Text(Localization.UnknownError.message)
					.font(.callout)
				
				Text(error.dumpedDescription())
					.font(.footnote)
			}
			
			Section {
				SendToDeveloperButton {
					"""
					Fehlerdetails:
					\(error.dumpedDescription())
					"""
				}
				
				DiscardButton(
					title: Localization.WipeAllData.button,
					symbol: "xmark",
					confirmationTitle: Localization.WipeAllData.warning,
					confirmationButton: Localization.WipeAllData.confirm
				) {
					AppDelegate.shared.wipeAllDataThenExit()
				}
			} header: {
				Text(Localization.actionsSection)
			}
		}
	}
	
	struct DiscardButton: View {
		var title: String
		var symbol: String?
		var confirmationTitle: String
		var confirmationButton: String?
		let discard: () -> Void
		
		@State var isConfirming = false
		
		@Environment(\.presentationMode) @Binding private var presentationMode
		
		var body: some View {
			Button {
				isConfirming = true
			} label: {
				Label(title, systemImage: symbol ?? "trash")
					.font(.body.weight(.medium))
			}
			.foregroundColor(.red)
			.actionSheet(isPresented: $isConfirming) {
				ActionSheet(
					title: Text(confirmationTitle),
					buttons: [
						.cancel(),
						.destructive(Text(confirmationButton ?? title)) {
							discard()
							presentationMode.dismiss()
						}
					]
				)
			}
		}
	}
	
	struct SendToDeveloperButton: View {
		let constructMessage: () -> String
		
		var body: some View {
			Link(destination: mailtoLink()) {
				Label(Localization.sendToDeveloper, systemImage: "envelope")
			}
		}
		
		func mailtoLink() -> URL {
			(URLComponents() <- {
				$0.scheme = "mailto"
				$0.queryItems = [
					.init(name: "to", value: "support@baupen.ch"),
					.init(name: "body", value: "\n\n" + constructMessage()),
				]
			})
			.url!
		}
	}
}

private struct NumberLabel: View {
	let number: Int?
	
	var body: some View {
		if let number {
			let text = Text("#\(number)")
			if #available(iOS 15.0, *) {
				text.monospacedDigit()
			} else {
				text
			}
		} else {
			Text(L10n.Issue.unregistered)
				.foregroundColor(.secondary)
		}
	}
}

struct ErrorDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		ErrorDetailsView(error: RequestError.pushFailed([1, 2, 15, 69].map { i in
			IssuePushError(
				stage: stages[(i) % 3],
				cause: RequestError.communicationError(RequestError.apiError(statusCode: i)),
				issue: makeIssue(number: i)
			)
		}))
		
		ErrorDetailsView(error: RequestError.communicationError(RequestError.apiError(statusCode: 418)))
	}
	
	static let stages = [IssuePushError.Stage.deletion, .imageUpload, .patch]
	static func makeIssue(number: Int) -> Issue {
		.init(
			meta: .init(),
			constructionSiteID: .init(),
			mapID: nil,
			number: number,
			wasAddedWithClient: false,
			deadline: nil,
			position: nil,
			description: "Testbeschreibung, die sehr lang ist und darum viele Zeilen bräuchte, um komplett angezeigt zu werden, wofür nun mal einfach kein Platz vorhanden ist.",
			status: .init(createdBy: .init()),
			wasUploaded: number % 2 == 0
		)
	}
}
