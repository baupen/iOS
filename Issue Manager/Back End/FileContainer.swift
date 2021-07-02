// Created by Julian Dunskus

import Foundation
import Promise

private let manager = FileManager.default

private let baseCacheURL = try! manager.url(
	for: .cachesDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)

private let baseLocalURL = try! manager.url(
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
}

private extension File {
	var subpath: String {
		let sanitized = urlPath.replacingOccurrences(of: "/", with: "#")
		return "files/\(Container.pathPrefix)/\(sanitized)"
	}
}

/// limit max concurrent file downloads
/// (otherwise we start getting overrun with timeouts, though URLSession automatically limits concurrent connections per host)
private let downloadLimiter = ConcurrencyLimiter(label: "file download", maxConcurrency: 3)

enum FileDownloadProgress: Hashable {
	/// going through local files to figure out what's missing, but also already downloading if necessary
	case undetermined
	/// downloading missing files, `current` out of `total` done
	case determined(current: Int, total: Int)
	/// downloads complete
	case done
}

extension FileContainer {
	static func cacheURL(for file: File<Self>) -> URL {
		baseCacheURL.appendingPathComponent(file.subpath, isDirectory: false)
	}
	
	static func localURL(for file: File<Self>) -> URL {
		baseLocalURL.appendingPathComponent(file.subpath, isDirectory: false)
	}
	
	static func downloadMissingFiles(
		onProgress: ((FileDownloadProgress) -> Void)? = nil
	) -> Future<Void> {
		onProgress?(.undetermined)
		
		let futures = Repository.shared.read(
			Self.order(Meta.Columns.lastChangeTime.desc)
				.withoutDeleted
				.fetchAll
		)
		.compactMap { $0.downloadFile() }
		
		guard let onProgress = onProgress else { return futures.sequence() }
		
		let total = futures.count
		var completed: Int32 = 0
		
		return futures
			.map {
				$0.map { _ in
					OSAtomicIncrement32(&completed)
					onProgress(.determined(current: Int(completed), total: total))
				}
			}
			.sequence()
			.always { onProgress(.done) }
	}
	
	/// - returns: A `Future` that resolves when the file is downloaded, or `nil` if there's nothing to do.
	@discardableResult func downloadFile() -> Future<Void>? {
		guard let file = file else { return nil }
		let url = Self.cacheURL(for: file)
		guard !manager.fileExists(atPath: url.path) else { return nil }
		
		return downloadLimiter.dispatch(_downloadFile)
	}
		
	private func _downloadFile() -> Future<Void> {
		// check again in case it's changed by now
		guard let file = file else { return .fulfilled }
		let url = Self.cacheURL(for: file)
		guard !manager.fileExists(atPath: url.path) else { return .fulfilled }
		
		let debugDesc = "for \(Self.pathPrefix) (id \(id))"
		print("Downloading \(file)", debugDesc)
		
		return Client.shared.download(file)
			.map { data in
				try? manager.createDirectory(
					at: url.deletingLastPathComponent(),
					withIntermediateDirectories: true
				)
				let success = manager.createFile(atPath: url.path, contents: data)
				print(success ? "Saved file to" : "Could not save file to", url, debugDesc)
			}
			.catch { error in
				error.printDetails(context: "Could not download \(file) \(debugDesc)")
			}
	}
	
	func fileUploaded(to location: File<Self>) {
		guard let file = file else { return }
		// doesn't matter if this fails; we'll end up being safe by downloading anyway
		try? manager.moveItem(
			at: Self.localURL(for: file),
			to: Self.cacheURL(for: location)
		)
	}
	
	func deleteFile() {
		guard let file = file else { return }
		try? manager.removeItem(at: Self.cacheURL(for: file))
		try? manager.removeItem(at: Self.localURL(for: file))
	}
}
