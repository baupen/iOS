// Created by Julian Dunskus

import SwiftUI
import GRDB

struct StorageSpaceView: View {
	private static let spaceFormatter = ByteCountFormatter() <- {
		$0.countStyle = .file
	}
	
	@State var overallDetails: StorageSpaceDetails?
	@State var spaceDetails: [ConstructionSite.ID: StorageSpaceDetails]?
	@State var downloadProgress = FileDownloadProgress.done
	
	var sites = Repository.shared.read(ConstructionSite.fetchAll)
	
	@Environment(\.presentationMode) @Binding var presentationMode
	
    var body: some View {
		NavigationView {
			List {
				Section {
					infoRows(for: overallDetails, issues: Issue.all())
				} header: {
					Text("Insgesamt")
				}
				
				Section {
					ForEach(sites) { site in
						let details = spaceDetails.map { $0[site.id] ?? .zero }
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
					Text("Nach Baustelle")
				}
			}
			.navigationTitle("Speicher Verwalten")
			.toolbar {
				ToolbarItemGroup(placement: .navigationBarLeading) {
					Button("Schliessen") {
						presentationMode.dismiss()
					}
				}
			}
		}
		.navigationViewStyle(.stack)
		.onAppear { calculateSpaceDetails() }
    }
	
	@ViewBuilder
	func infoRows(for details: StorageSpaceDetails?, issues: QueryInterfaceRequest<Issue>) -> some View {
		spaceRow(label: "Verwendet:", bytes: details?.usedSpace)
		spaceRow(label: "Einsparbar:", bytes: details?.purgeableSpace)
		
		VStack(spacing: 8) {
			Button("Jetzt Platz Einsparen") {
				Issue.purgeInactiveFiles(for: issues)
				recalculateSpaceDetails()
			}
			.buttonStyle(.plain)
			.foregroundColor(.accentColor)
			
			Text("Um Daten zu sparen, werden nur Bilder von aktiven Pendenzen heruntergeladen. Bereits geladene Bilder können mit diesem Knopf lokal entfernt werden.")
				.font(.footnote)
				.foregroundColor(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.padding(.vertical, 8)
		
		VStack {
			switch downloadProgress {
			case .undetermined:
				ProgressView()
				Text(L10n.SiteList.FileProgress.indeterminate)
			case .determined(let current, let total):
				ProgressView(value: Double(current), total: Double(total))
				Text(L10n.SiteList.FileProgress.determinate(current, total))
			case .done:
				Button("Alle Bilder Laden") {
					Issue.downloadMissingFiles(for: issues, includeInactive: true) {
						downloadProgress = $0
					}
					.then(recalculateSpaceDetails)
				}
				.frame(maxWidth: .infinity)
			}
		}
		.progressViewStyle(.linear)
		.padding(.vertical, 8)
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
	
	func recalculateSpaceDetails() {
		overallDetails = nil
		spaceDetails = nil
		calculateSpaceDetails()
	}
	
	private static let calculationQueue = DispatchQueue(label: "storage space calculation")
	
	func calculateSpaceDetails() {
		guard overallDetails == nil else { return } // already working on it
		Self.calculationQueue.async {
			let issues = Repository.shared.read(Issue.fetchAll)
			let issuesByFilename = Dictionary(uniqueKeysWithValues: issues.compactMap { issue in
				issue.file.map { ($0.localFilename, issue) }
			})
			
			let imageURLs = try! FileManager.default.contentsOfDirectory(
				at: Issue.baseLocalFolder,
				includingPropertiesForKeys: [.fileSizeKey]
			)
			
			var total = StorageSpaceDetails.zero
			var detailsBySite: [ConstructionSite.ID: StorageSpaceDetails] = [:]
			for imageURL in imageURLs {
				let values = try! imageURL.resourceValues(forKeys: [.fileSizeKey])
				let size = values.fileSize!
				
				total.usedSpace += size
				guard let issue = issuesByFilename[imageURL.lastPathComponent] else {
					print("could not find issue for \(imageURL)!")
					continue
				}
				var siteDetails = detailsBySite[issue.constructionSiteID] ?? .zero
				siteDetails.usedSpace += size
				if !issue.shouldAutoDownloadFile {
					total.purgeableSpace += size
					siteDetails.purgeableSpace += size
				}
				detailsBySite[issue.constructionSiteID] = siteDetails
			}
			
			DispatchQueue.main.async {
				overallDetails = total
				spaceDetails = detailsBySite
			}
		}
	}
}

struct StorageSpaceDetails {
	static let zero = Self(usedSpace: 0, purgeableSpace: 0)
	
	var usedSpace: Int
	var purgeableSpace: Int
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
			overallDetails: .init(usedSpace: 12_345_678_901, purgeableSpace: 1_234_567_890),
			spaceDetails: [:],
			downloadProgress: .determined(current: 42, total: 69),
			sites: [exampleSite]
		)
    }
}
