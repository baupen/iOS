// Created by Julian Dunskus

import Foundation
import Promise

typealias DownloadRequestPath<T: StoredObject> = WritableKeyPath<FileDownloadRequest, ObjectMeta<T>?>

struct FileDownloadRequest: JSONDataRequest {
	static let isIndependent = true
	
	var method: String { return "file/download" }
	
	var authenticationToken: String
	var constructionSite: ObjectMeta<ConstructionSite>? = nil
	var map: ObjectMeta<Map>? = nil
	var issue: ObjectMeta<Issue>? = nil
	
	init<T: StoredObject>(authenticationToken: String, requestingFileFor path: DownloadRequestPath<T>, meta: ObjectMeta<T>) {
		self.authenticationToken = authenticationToken
		self[keyPath: path] = meta
	}
}

extension Client {
	func downloadFile<T: StoredObject>(for path: DownloadRequestPath<T>, meta: ObjectMeta<T>) -> Future<Data> {
		return getUser()
			.map { user in
				FileDownloadRequest(
					authenticationToken: user.authenticationToken,
					requestingFileFor: path,
					meta: meta
				)
			}.flatMap(send)
	}
}
