// Created by Julian Dunskus

import Foundation

private let manager = FileManager.default

/// can be deleted at any time, used for images that are no longer immediately in use (e.g. sites that have been deselected or from other accounts)
private let baseCacheURL = try! manager.url(
	for: .cachesDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)

/// for images from all sites the user has access to
private let baseLocalURL = try! manager.url(
	for: .applicationSupportDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)

/// to migrate data from previous installations
private let baseLegacyLocalURL = try! manager.url(
	for: .documentDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)

func wipeDownloadedFiles() {
	[baseCacheURL, baseLocalURL]
		.compactMap { try? manager.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil) }
		.joined()
		.forEach { try? manager.removeItem(at: $0) }
}

protocol FileContainer: StoredObject {
	static var pathPrefix: String { get }
	
	var file: File<Self>? { get }
	var shouldAutoDownloadFile: Bool { get }
}

extension File {
	fileprivate static var subpath: String {
		"files/\(Container.pathPrefix)"
	}
	
	var localFilename: String {
		urlPath.replacingOccurrences(of: "/", with: "#")
	}
	
	func onUpload(as file: Self) throws  {
		try manager.moveItem(
			at: Container.localURL(for: self),
			to: Container.localURL(for: file)
		)
	}
}

enum FileDownloadProgress: Hashable {
	/// going through local files to figure out what's missing, but also already downloading if necessary
	case undetermined
	/// downloading missing files, `current` out of `total` done
	case determined(current: Int, total: Int)
	/// downloads complete
	case done
}

extension Issue {
	/// Since we're changing from the documents folder to the application support folder, we should make sure to take any issue images from the former that haven't been uploaded yet with us.
	static func moveLegacyFiles() {
		let legacy = baseLegacyLocalURL.appendingPathComponent(File<Self>.subpath, isDirectory: true)
		guard manager.fileExists(atPath: legacy.path) else { return }
		try! manager.createDirectory(
			at: baseLocalFolder.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		print("migrating legacy files from \(legacy) to \(baseLocalFolder)")
		do {
			try manager.moveItem(at: legacy, to: baseLocalFolder)
		} catch {
			error.printDetails(context: "could not migrate legacy files!")
		}
	}
}

extension FileContainer {
	var shouldAutoDownloadFile: Bool { true }
	
	private static var baseCacheFolder: URL {
		baseCacheURL.appendingPathComponent(File<Self>.subpath, isDirectory: true)
	}
	
	static var baseLocalFolder: URL {
		baseLocalURL.appendingPathComponent(File<Self>.subpath, isDirectory: true)
	}
	
	private static func cacheURL(for file: File<Self>) -> URL {
		baseCacheFolder.appendingPathComponent(file.localFilename, isDirectory: false)
	}
	
	static func localURL(for file: File<Self>) -> URL {
		baseLocalFolder.appendingPathComponent(file.localFilename, isDirectory: false)
	}
	
	/// Identifies files in the local folder that are no longer actively needed (e.g. because their construction site is no longer selected for this user), and moves them to the caches folder.
	static func moveDisusedFiles(inUse: [Self]) {
		let allLocalFiles: Set<String>
		do {
			allLocalFiles = Set(try manager.contentsOfDirectory(atPath: baseLocalFolder.path))
		} catch {
			error.printDetails(context: "could not establish present files in \(baseLocalFolder)")
			return
		}
		
		let necessaryFiles = inUse.compactMap(\.file?.localFilename)
		let filesToMove = allLocalFiles.subtracting(necessaryFiles)
		
		// move all files that are no longer necessary to the caches folder
		try? manager.createDirectory(at: baseCacheFolder, withIntermediateDirectories: true, attributes: nil)
		for filename in filesToMove {
			let localURL = baseLocalFolder.appendingPathComponent(filename, isDirectory: false)
			let cacheURL = baseCacheFolder.appendingPathComponent(filename, isDirectory: false)
			do {
				try? manager.removeItem(at: cacheURL)
				try manager.moveItem(at: localURL, to: cacheURL)
			} catch {
				error.printDetails(context: "could not move local file at \(localURL) to \(cacheURL)")
			}
		}
	}
	
	static func purgeInactiveFiles(
		for containers: Self.Query = Self.all(),
		in repository: Repository
	) {
		let allContainers = repository.read(containers.fetchAll)
		for container in allContainers where !container.shouldAutoDownloadFile {
			container.deleteFile()
		}
	}
	
	static func downloadMissingFiles(
		for containers: Self.Query? = nil,
		in repository: Repository,
		using client: Client,
		includeInactive: Bool = false,
		onProgress: ProgressHandler<FileDownloadProgress> = .ignore
	) async throws {
		try await onProgress.unisolated { onProgress in
			onProgress(.undetermined)
			
			// bookkeeping
			let allContainers = repository.read(
				(containers ?? all())
					.withoutDeleted
					.order(Meta.Columns.lastChangeTime.desc)
					.fetchAll
			)
			if containers == nil { // can't do this when only handling a subset
				moveDisusedFiles(inUse: allContainers)
			}
			
			// figure out what to download
			let activeContainers = includeInactive
			? allContainers
			: allContainers.filter(\.shouldAutoDownloadFile)
			let filesToDownload = activeContainers.filter { $0.checkForFileDownload() }
			print("\(Self.self): downloading files for \(filesToDownload.count)/\(activeContainers.count) containers")
			onProgress(.determined(current: 0, total: filesToDownload.count))
			
			// parallel downloads
			let context = await client.makeContext()
			var completed = 0
			// limit concurrent downloads to avoid overwhelming the server
			try await filesToDownload.concurrentForEach(slots: 5) { container in
				try await container.downloadFile(using: context)
			} onProgress: {
				completed += 1
				onProgress(.determined(current: completed, total: filesToDownload.count))
			}
			
			onProgress(.done)
		}
	}
	
	func downloadFileIfNeeded(using client: Client) async throws {
		guard checkForFileDownload() else { return }
		try await downloadFile(using: await client.makeContext())
	}
	
	// returns whether the file needs to be downloaded
	func checkForFileDownload() -> Bool {
		guard let file = file else { return false }
		
		// check if it already exists
		let url = Self.localURL(for: file)
		guard !manager.fileExists(atPath: url.path) else { return false }
		
		// check if we already have it cached
		let cached = Self.cacheURL(for: file)
		if manager.fileExists(atPath: cached.path) {
			do {
				try manager.moveItem(at: cached, to: url)
				return false
			} catch {
				error.printDetails(context: "could not restore local file at \(url) from cached file at \(cached)")
			}
		}
		
		return true // needs download
	}
	
	private func downloadFile(using context: RequestContext) async throws {
		// check again in case it's changed by now (defensive coding, i know…)
		guard let file = file else { return }
		let url = Self.localURL(for: file)
		guard !manager.fileExists(atPath: url.path) else { return }
		
		let debugDesc = "for \(Self.pathPrefix) (id \(id))"
		print("Downloading \(file)", debugDesc)
		
		do {
			let data = try await context.download(file)
			try? manager.createDirectory(
				at: url.deletingLastPathComponent(),
				withIntermediateDirectories: true
			)
			let success = manager.createFile(atPath: url.path, contents: data)
			print(success ? "Saved file to" : "Could not save file to", url, debugDesc)
		} catch {
			error.printDetails(context: "Could not download \(file) \(debugDesc)")
		}
	}
	
	func deleteFile() {
		guard let file = file else { return }
		try? manager.removeItem(at: Self.cacheURL(for: file))
		try? manager.removeItem(at: Self.localURL(for: file))
	}
}
