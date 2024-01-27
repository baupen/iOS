import Foundation
import HandyOperators

struct StorageSpaceDetails {
	var total: Group
	var bySite: [ConstructionSite.ID: Group]
	var startTime: Date
	
	struct Group {
		var usedSpace: Int = 0
		var purgeableSpace: Int = 0
		var missingImages: Int = 0
	}
	
	@MainActor // TODO: remove in Swift 5.10+
	private static let calculationTaskManager = TaskManager<StorageSpaceDetails, Never>()
	
	@MainActor
	static func calculate() async -> StorageSpaceDetails {
		await calculationTaskManager.runIfNewest { @Sendable in
			Task.detached(priority: .userInitiated) {
				doCalculate()
			}
		}.value
	}
	
	private static func doCalculate() -> StorageSpaceDetails {
		let startTime = Date.now
		
		let issues = Repository.read(Issue.all().withoutDeleted.fetchAll)
		let issuesWithFiles = issues.compactMap { issue in
			issue.file.map { (issue: issue, file: $0) }
		}
		let issuesByFilename = Dictionary(
			uniqueKeysWithValues: issuesWithFiles.map { ($0.file.localFilename, $0.issue) }
		)
		let filesBySite: [ConstructionSite.ID: Int] = [:] <- { filesBySite in
			for (issue, _) in issuesWithFiles {
				filesBySite[issue.constructionSiteID, default: 0] += 1
			}
		}
		
		// rather than lots of little filesystem requests, we'll just do one directory listing and work with that.
		let imageURLs = try! FileManager.default.contentsOfDirectory(
			at: Issue.baseLocalFolder,
			includingPropertiesForKeys: [.fileSizeKey]
		)
		
		return Self(
			total: .init(missingImages: issuesWithFiles.count),
			bySite: filesBySite.mapValues { .init(missingImages: $0) },
			startTime: startTime
		) <- { details in
			for imageURL in imageURLs {
				let values = try! imageURL.resourceValues(forKeys: [.fileSizeKey])
				let size = values.fileSize!
				
				details.total.missingImages -= 1
				details.total.usedSpace += size
				
				guard let issue = issuesByFilename[imageURL.lastPathComponent] else {
					print("could not find issue for \(imageURL)!")
					continue
				}
				
				var siteDetails = details.bySite[issue.constructionSiteID] ?? .init()
				siteDetails.missingImages -= 1
				siteDetails.usedSpace += size
				if !issue.shouldAutoDownloadFile {
					details.total.purgeableSpace += size
					siteDetails.purgeableSpace += size
				}
				details.bySite[issue.constructionSiteID] = siteDetails
			}
		}
	}
}
