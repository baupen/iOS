// Created by Julian Dunskus

import SwiftUI

struct ViewOptionsEditor: View {
	typealias Status = Issue.Status.Simplified
	typealias Localization = L10n.ViewOptions
	
	@ObservedObject var options = ViewOptions.shared
	
	@Environment(\.presentationMode) @Binding private var presentationMode
	
	var body: some View {
		NavigationView {
			Form {
				Section {
					Toggle(L10n.SiteList.ClientMode.title, isOn: $options.isInClientMode)
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
		ViewOptionsEditor(options: .init(visibleStatuses: []))
		ViewOptionsEditor(options: .init(visibleStatuses: [.new]))
		ViewOptionsEditor(options: .init(visibleStatuses: [.new, .registered, .resolved, .closed]))
	}
}
