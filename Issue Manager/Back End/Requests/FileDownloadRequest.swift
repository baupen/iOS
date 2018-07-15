// Created by Julian Dunskus

import Foundation

typealias DownloadRequestPath = WritableKeyPath<FileDownloadRequest, ObjectMeta?>

struct FileDownloadRequest: JSONDataRequest {
	static let isIndependent = true
	
	var method: String { return "file/download" }
	
	// mutable for keypath stuff
	private(set) var authenticationToken: String
	private(set) var building: ObjectMeta? = nil
	private(set) var map: ObjectMeta? = nil
	private(set) var issue: ObjectMeta? = nil
	
	init(authenticationToken: String, requestingFileFor path: DownloadRequestPath, meta: ObjectMeta) {
		self.authenticationToken = authenticationToken
		self[keyPath: path] = meta
	}
}

extension Client {
	func downloadFile(for path: DownloadRequestPath, meta: ObjectMeta) -> Future<Data> {
		return getUser()
			.map { user in
				FileDownloadRequest(
					authenticationToken: user.authenticationToken,
					requestingFileFor: path,
					meta: meta
				)
			}.flatMap(Client.shared.send)
	}
}
