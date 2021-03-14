// Created by Julian Dunskus

import Foundation
import Promise

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

extension Client {
	func download(_ file: AnyFile) -> Future<Data> {
		send(FileDownloadRequest(file: file))
	}
}
