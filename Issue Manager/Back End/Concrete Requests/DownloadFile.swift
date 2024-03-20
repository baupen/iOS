// Created by Julian Dunskus

import Foundation
import Protoquest

private struct FileDownloadRequest: GetDataRequest, BaupenRequest {
	var path: String
	
	var size: String? = "full"
	
	init(file: AnyFile) {
		path = file.urlPath
	}
	
	var urlParams: [URLParameter] {
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
