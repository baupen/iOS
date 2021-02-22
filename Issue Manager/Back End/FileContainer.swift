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
	
	static func cacheURL(for file: File<Self>) -> URL
	static func localURL(for file: File<Self>) -> URL
	
	var file: File<Self>? { get }
	
	@discardableResult func downloadFile() -> Future<Void>
	@discardableResult func downloadFile(previous: Self?) -> Future<Void>
	func deleteFile()
}

// TODO: make sure to delete existing caches on first launch of new version

private extension File {
	var subpath: String {
		let sanitized = urlPath.replacingOccurrences(of: "/", with: "#")
		return "files/\(Container.pathPrefix)/\(sanitized)"
	}
}

extension FileContainer {
	static func cacheURL(for file: File<Self>) -> URL {
		baseCacheURL.appendingPathComponent(file.subpath, isDirectory: false)
	}
	
	static func localURL(for file: File<Self>) -> URL {
		baseLocalURL.appendingPathComponent(file.subpath, isDirectory: false)
	}
	
	static func onChange(from previous: Self?, to new: Self?) {
		if let new = new {
			new.downloadFile(previous: previous)
		} else {
			previous?.deleteFile()
		}
	}
	
	func downloadFile() -> Future<Void> {
		downloadFile(previous: nil)
	}
	
	func downloadFile(previous: Self?) -> Future<Void> {
		if let previous = previous {
			switch (previous.file, file) {
			case (nil, nil): // never had file
				return .fulfilled // nothing to do
			case (nil, _?): // newly has file
				break // nothing to do here; just download file
			case (_?, nil): // no longer has file
				previous.deleteFile()
			case let (prev?, new?) where prev == new: // same file
				// move after uploading
				try? manager.moveItem(
					at: Self.localURL(for: prev),
					to: Self.cacheURL(for: new)
				)
				return .fulfilled
			case (_?, _?): // different file
				previous.deleteFile()
			}
		}
		
		guard let file = file else { return .fulfilled }
		let url = Self.cacheURL(for: file)
		
		guard !manager.fileExists(atPath: url.path) else { return .fulfilled }
		
		print("Downloading \(file) for \(Self.pathPrefix)")
		
		return Client.shared.download(file)
			.map { data in
				try? manager.createDirectory(at: url, withIntermediateDirectories: true)
				let success = manager.createFile(atPath: url.path, contents: data)
				print(success ? "Saved file to" : "Could not save file to", url)
			}
			.catch { error in
				error.printDetails(context: "Could not download \(file)")
				//print("container to download file for:")
				//dump(self)
				//print()
			}
	}
	
	func deleteFile() {
		guard let file = file else { return }
		try? manager.removeItem(at: Self.cacheURL(for: file))
		try? manager.removeItem(at: Self.localURL(for: file))
	}
}
