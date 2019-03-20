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

protocol FileContainer: APIObject {
	static var pathPrefix: String { get }
	static var downloadRequestPath: DownloadRequestPath<Self> { get }
	
	static func cacheURL(for file: File) -> URL
	static func localURL(for file: File) -> URL
	
	var file: File? { get }
	
	func downloadFile()
	func downloadFile(previous: Self?)
	func deleteFile()
}

extension FileContainer {
	static func cacheURL(for file: File) -> URL {
		let url = baseCacheURL.appendingPathComponent("files/\(Self.pathPrefix)/\(file.id.stringValue)")
		try? manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
		return url
	}
	
	static func localURL(for file: File) -> URL {
		let url = baseLocalURL.appendingPathComponent("files/\(Self.pathPrefix)/\(file.id.stringValue)")
		try? manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
		return url
	}
	
	static func update(_ instance: inout Self?, from new: Self?) {
		if let new = new {
			new.downloadFile(previous: instance)
		} else {
			instance?.deleteFile()
		}
		instance = new
	}
	
	func downloadFile() {
		downloadFile(previous: nil)
	}
	
	func downloadFile(previous: Self?) {
		if let previous = previous {
			switch (previous.file, file) {
			case (nil, nil): // never had file
				return // nothing to do
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
				return
			case (_?, _?): // different file
				previous.deleteFile()
			}
		}
		
		guard let file = file else { return }
		let url = Self.cacheURL(for: file)
		
		guard !manager.fileExists(atPath: url.path) else { return }
		
		print("Downloading \(file) for \(Self.pathPrefix)")
		
		let result = Client.shared.downloadFile(for: Self.downloadRequestPath, meta: meta)
		result.then { data in
			let success = manager.createFile(atPath: url.path, contents: data)
			print(success ? "Saved file to" : "Could not save file to", url)
		}
		
		result.catch { error in
			error.printDetails(context: "Could not download \(file)")
			print("container to download file for:")
			dump(self)
			print()
		}
	}
	
	func deleteFile() {
		try? file.map(Self.cacheURL).map(manager.removeItem)
		try? file.map(Self.localURL).map(manager.removeItem)
	}
}
