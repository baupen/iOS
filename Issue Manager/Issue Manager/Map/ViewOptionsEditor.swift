// Created by Julian Dunskus

import SwiftUI

struct ViewOptionsEditor: View {
	typealias Status = Issue.Status.Simplified
	typealias Localization = L10n.ViewOptions
	
	var craftsmen: [Craftsman]
	@ObservedObject var options = ViewOptions.shared
	
	@Environment(\.presentationMode) @Binding private var presentationMode
	
	var body: some View {
		NavigationView {
			Form {
				Section {
					clientModeToggle()
					craftsmanFilterLink()
				}
				
				Section {
					ForEach(Status.allCases, id: \.self, content: statusButton(for:))
				} header: {
					Text(Localization.StatusFilter.title)
				} footer: {
					Text(summary)
				}
			}
			.navigationTitle(Localization.title)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				Button {
					presentationMode.dismiss()
				} label: {
					Text(L10n.Button.done)
						.fontWeight(.medium)
				}
			}
		}
		.navigationViewStyle(.stack)
	}
	
	@ViewBuilder
	func clientModeToggle() -> some View {
		let toggle = Toggle(L10n.SiteList.ClientMode.title, isOn: $options.isInClientMode)
		if #available(iOS 15.0, *) {
			toggle.tint(.accentColor)
		} else {
			// green is fine i guess lol
			toggle
		}
	}
	
	func craftsmanFilterLink() -> some View {
		NavigationLink {
			craftsmanFilter()
		} label: {
			HStack {
				Text(Localization.CraftsmanFilter.Label.title)
				
				Spacer()
				
				Group {
					let shown = craftsmen.filter { !options.hiddenCraftsmen.contains($0.id) }
					if options.hiddenCraftsmen.isEmpty {
						Text(Localization.CraftsmanFilter.Label.allVisible)
					} else if shown.count == 1 {
						Text(shown.first!.company)
					} else {
						Text(Localization.CraftsmanFilter.Label.visibleCount(shown.count))
					}
				}
				.foregroundColor(.secondary)
			}
		}
	}
	
	@ViewBuilder
	func craftsmanFilter() -> some View {
		List {
			let craftsmanIDs: Set<Craftsman.ID?> = Set(craftsmen.lazy.map(\.id))
			
			Section {
				Button {
					options.hiddenCraftsmen = []
				} label: {
					Text(Localization.CraftsmanFilter.showAll)
				}
				
				Button {
					options.hiddenCraftsmen = craftsmanIDs.union([nil])
				} label: {
					Text(Localization.CraftsmanFilter.hideAll)
				}
			}
			
			Section {
				Button {
					options.hiddenCraftsmen.formSymmetricDifference([nil])
				} label: {
					HStack {
						VStack(alignment: .leading) {
							Text(Localization.CraftsmanFilter.withoutCraftsman)
								.foregroundColor(.primary)
						}
						Spacer()
						Image(systemName: "checkmark")
							.opacity(options.hiddenCraftsmen.contains(nil) ? 0 : 1)
					}
				}
				
				ForEach(craftsmen, id: \.id) { craftsman in
					Button {
						options.hiddenCraftsmen.formSymmetricDifference([craftsman.id])
					} label: {
						HStack {
							VStack(alignment: .leading) {
								Text(craftsman.company)
									.foregroundColor(.primary)
								Text(craftsman.trade)
									.foregroundColor(.secondary)
							}
							Spacer()
							Image(systemName: "checkmark")
								.opacity(options.hiddenCraftsmen.contains(craftsman.id) ? 0 : 1)
						}
					}
				}
			}
		}
		.navigationTitle(Localization.CraftsmanFilter.title)
	}
	
	@ViewBuilder
	func statusButton(for status: Status) -> some View {
		Button {
			options.visibleStatuses.formSymmetricDifference([status])
		} label: {
			HStack {
				Image(uiImage: status.flatIcon)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 22)
				Text(status.localizedName)
					.accentColor(.primary)
				Spacer()
				Image(systemName: "checkmark")
					.opacity(options.visibleStatuses.contains(status) ? 1 : 0)
			}
		}
	}
	
	var summary: String {
		switch options.visibleStatuses.count {
		case Status.allCases.count:
			return Localization.StatusFilter.allSelected
		case 0:
			return Localization.StatusFilter.noneSelected
		default:
			return Localization.StatusFilter.someSelected
		}
	}
}

struct StatusFilterEditor_Previews: PreviewProvider {
	static var previews: some View {
		let siteID = ConstructionSite.ID()
		let craftsmen = (1...3).map {
			Craftsman(meta: .init(), constructionSiteID: siteID, contactName: "Kontakt", company: "Unternehmer #\($0)", trade: "Gewerk #\($0)")
		}
		ViewOptionsEditor(craftsmen: craftsmen, options: .init(
			visibleStatuses: [],
			hiddenCraftsmen: []
		))
		ViewOptionsEditor(craftsmen: craftsmen, options: .init(
			visibleStatuses: [.new],
			isInClientMode: true,
			hiddenCraftsmen: .init(craftsmen.dropLast().map(\.id))
		))
		ViewOptionsEditor(craftsmen: craftsmen, options: .init(
			visibleStatuses: [.new, .registered, .resolved, .closed],
			hiddenCraftsmen: .init(craftsmen.map(\.id))
		))
	}
}
