// Created by Julian Dunskus

import Foundation

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

protocol AnyFileContainer: AnyAPIObject {
	var filename: String? { get }
	
	func deleteFile()
	func downloadFile()
	func downloadFile(previous: AnyFileContainer?)
}

protocol FileContainer: AnyFileContainer, APIObject {
	static var pathPrefix: String { get }
	static var downloadRequestPath: DownloadRequestPath<Self> { get }
	
	static func cacheURL(filename: String) -> URL
	static func localURL(filename: String) -> URL
}

extension FileContainer {
	static func cacheURL(filename: String) -> URL {
		let url = baseCacheURL.appendingPathComponent("files/\(Self.pathPrefix)/\(filename)")
		try? manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
		return url
	}
	
	static func localURL(filename: String) -> URL {
		let url = baseLocalURL.appendingPathComponent("files/\(Self.pathPrefix)/\(filename)")
		try? manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
		return url
	}
	
	func downloadFile() {
		downloadFile(previous: nil)
	}
	
	func downloadFile(previous: AnyFileContainer?) {
		if let previous = previous {
			switch (previous.filename, filename) {
			case (nil, nil): // never had file
				return // nothing to do
			case (nil, _?): // newly has file
				break // nothing to do here; just download file
			case (_?, nil): // no longer has file
				previous.deleteFile()
			case let (prev?, new?) where prev == new: // same file
				// move after uploading
				try? manager.moveItem(
					at: Self.localURL(filename: prev),
					to: Self.cacheURL(filename: new)
				)
				return
			case (_?, _?): // different file
				previous.deleteFile()
			}
		}
		
		guard let filename = filename else { return }
		let url = Self.cacheURL(filename: filename)
		
		guard !manager.fileExists(atPath: url.path) else { return }
		
		print("Downloading file \(filename) for \(Self.pathPrefix)")
		
		let result = Client.shared.downloadFile(for: Self.downloadRequestPath, meta: meta)
		result.then { data in
			let success = manager.createFile(atPath: url.path, contents: data)
			print(success ? "Saved file to" : "Could not save file to", url)
		}
		
		result.catch { error in
			print("Could not download the file named \(filename)")
			print(error.localizedFailureReason)
			dump(error)
			print("container to download file for:")
			dump(self)
			print()
		}
	}
	
	func deleteFile() {
		try? filename.map(Self.cacheURL).map(manager.removeItem)
		try? filename.map(Self.localURL).map(manager.removeItem)
	}
}
