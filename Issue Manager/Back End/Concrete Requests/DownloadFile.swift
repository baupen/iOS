// Created by Julian Dunskus

import Foundation
import Promise

private struct FileDownloadRequest: GetDataRequest {
	var path: String
	
	init(file: AnyFile) {
		path = file.urlPath
	}
}

extension Client {
	/// limit max concurrent file downloads
	/// (otherwise we start getting overrun with timeouts, though URLSession automatically limits concurrent connections per host)
	private static let downloadLimiter = ConcurrencyLimiter(label: "file download", maxConcurrency: 16)
	
	// TODO: cancel requests if already downloaded?
	
	func download(_ file: AnyFile) -> Future<Data> {
		Self.downloadLimiter.dispatch {
			self.send(FileDownloadRequest(file: file))
		}
	}
}
