// Created by Julian Dunskus

import Foundation
import Promise

typealias DownloadRequestPath<T: APIObject> = WritableKeyPath<FileDownloadRequest, ObjectMeta<T>?>

struct FileDownloadRequest: JSONDataRequest {
	static let isIndependent = true
	
	var method: String { return "file/download" }
	
	// mutable for keypath stuff
	private(set) var authenticationToken: String
	private(set) var constructionSite: ObjectMeta<ConstructionSite>? = nil
	private(set) var map: ObjectMeta<Map>? = nil
	private(set) var issue: ObjectMeta<Issue>? = nil
	
	init<T: APIObject>(authenticationToken: String, requestingFileFor path: DownloadRequestPath<T>, meta: ObjectMeta<T>) {
		self.authenticationToken = authenticationToken
		self[keyPath: path] = meta
	}
}

extension Client {
	func downloadFile<T: APIObject>(for path: DownloadRequestPath<T>, meta: ObjectMeta<T>) -> Future<Data> {
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
