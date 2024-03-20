// Created by Julian Dunskus

import SwiftUI
import HandyOperators

@MainActor
struct StorageSpaceView: View {
	fileprivate typealias Localization = L10n.ManageStorage
	
	private static let spaceFormatter = ByteCountFormatter() <- {
		$0.countStyle = .file
	}
	
	@State var details: StorageSpaceDetails?
	@State var lastUpdate = Date()
	@State var downloadProgress = FileDownloadProgress.done
	@State var cancelDownloads: (() -> Void)?
	
	var sites = Repository.read(ConstructionSite.fetchAll)
	
	@Environment(\.presentationMode) @Binding var presentationMode
	
    var body: some View {
		NavigationView {
			List {
				Section {
					infoRows(for: details?.total, issues: Issue.all())
				} header: {
					Text(Localization.Section.total)
				}
				
				Section {
					ForEach(sites) { site in
						let details = details.map { $0.bySite[site.id] ?? .init() }
						NavigationLink {
							List {
								infoRows(for: details, issues: site.issues)
							}
							.navigationTitle(site.name)
						} label: {
							spaceRow(label: site.name, bytes: details?.usedSpace)
						}
					}
				} header: {
					Text(Localization.Section.bySite)
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
		.onAppear {
			if details == nil {
				calculateSpaceDetails()
			}
		}
		.onDisappear {
			cancelDownloads?()
		}
    }
	
	@ViewBuilder
	func infoRows(for details: StorageSpaceDetails.Group?, issues: Issue.Query) -> some View {
		spaceRow(label: Localization.spaceUsed, bytes: details?.usedSpace)
		spaceRow(label: Localization.spacePurgeable, bytes: details?.purgeableSpace)
		
		cellVStack {
			Button(Localization.purgeNow) {
				Issue.purgeInactiveFiles(for: issues)
				calculateSpaceDetails()
			}
			.buttonStyle(.plain)
			.foregroundColor(.accentColor)
			
			Text(Localization.purgeInfo)
				.font(.footnote)
				.foregroundColor(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		
		cellVStack {
			let cancelButton = Button(Localization.cancelDownload) {
				cancelDownloads?()
			}
			
			switch downloadProgress {
			case .undetermined:
				ProgressView()
				Text(L10n.SiteList.FileProgress.indeterminate)
				cancelButton
			case .determined(let current, let total):
				ProgressView(value: Double(current), total: Double(total))
				Text(L10n.SiteList.FileProgress.determinate(current, total))
				cancelButton
			case .done:
				if let details = details {
					if details.missingImages == 0 {
						Text(Localization.allImagesDownloaded)
							.foregroundColor(.secondary)
					} else {
						Button(Localization.downloadAll(details.missingImages)) {
							let task = Task {
								try await downloadMissingFiles(for: issues)
							}
							cancelDownloads?()
							cancelDownloads = {
								task.cancel()
								print("cancelled")
								downloadProgress = .done
							}
						}
					}
				} else {
					ProgressView()
				}
			}
		}
	}
	
	func downloadMissingFiles(for issues: Issue.Query) async throws {
		var lastUpdate = Date.now
		try await Issue.downloadMissingFiles(
			for: issues, includeInactive: true,
			onProgress: .onMainActor {
				downloadProgress = $0
				
				let now = Date()
				if now.timeIntervalSince(lastUpdate) > 20 {
					lastUpdate = now
					// recalculate every 20 seconds to provide up-to-date info while avoiding too much battery drainage
					// (this function already makes sure only one task is running at a time)
					calculateSpaceDetails()
				}
			}
		)
		calculateSpaceDetails()
	}
	
	func cellVStack(@ViewBuilder content: () -> some View) -> some View {
		VStack(spacing: 8) {
			content()
		}
		.padding(.vertical, 8)
		.frame(maxWidth: .infinity)
	}
	
	func spaceRow(label: String, bytes: Int?) -> some View {
		HStack {
			Text(label)
			
			Spacer()
			
			if let bytes = bytes {
				Text(bytes as NSNumber, formatter: Self.spaceFormatter)
					.foregroundColor(.secondary)
			} else {
				ProgressView()
			}
		}
	}
	
	func calculateSpaceDetails() {
		Task {
			let new = await StorageSpaceDetails.calculate()
			guard new.startTime > details?.startTime ?? .distantPast else { return }
			details = new
		}
	}
}

struct StorageSpaceView_Previews: PreviewProvider {
    static var previews: some View {
		let exampleSite = ConstructionSite(
			meta: .init(),
			name: "Beispiel-Baustelle",
			creationTime: .init(),
			image: nil,
			managerIDs: .init()
		)
		
        StorageSpaceView(
			details: .init(
				total: .init(usedSpace: 12_345_678_901, purgeableSpace: 1_234_567_890, missingImages: 1337),
				bySite: [:], startTime: .now
			),
			downloadProgress: .determined(current: 42, total: 69),
			sites: [exampleSite]
		)
		
		StorageSpaceView(
			details: .init(
				total: .init(usedSpace: 12_345_678_901, purgeableSpace: 1_234_567_890, missingImages: 1337),
				bySite: [:], startTime: .now
			),
			sites: [exampleSite]
		)
		.preferredColorScheme(.dark)
    }
}
