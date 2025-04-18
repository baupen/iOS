// Created by Julian Dunskus

import Foundation
import Protoquest
import HandyOperators

private struct FileDownloadRequest: GetDataRequest, BaupenRequest {
	var path: String
	
	var size: String? = "full"
	
	init(file: AnyFile) throws {
		path = try file.urlPath.removingPercentEncoding ??? RequestConstructionError.percentDecodingFailed(file.urlPath)
	}
	
	var urlParams: [URLParameter] {
		if let size = size {
			("size", size)
		}
	}
	
	enum RequestConstructionError: Error {
		case percentDecodingFailed(String)
	}
}

extension RequestContext {
	func download(_ file: AnyFile) async throws -> Data {
		try await send(FileDownloadRequest(file: file))
	}
}
