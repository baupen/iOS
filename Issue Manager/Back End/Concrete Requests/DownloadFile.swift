// Created by Julian Dunskus

import Foundation

private struct FileDownloadRequest: GetDataRequest {
	var path: String
	
	var size: String? = "full"
	
	init(file: AnyFile) {
		path = file.urlPath
	}
	
	func collectURLQueryItems() -> [(String, Any)] {
		if let size = size {
			("size", size)
		}
	}
}

extension RequestContext {
	func download(_ file: AnyFile) async throws -> Data {
		try await send(FileDownloadRequest(file: file))
	}
}
