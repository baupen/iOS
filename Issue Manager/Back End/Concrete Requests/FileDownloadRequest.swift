// Created by Julian Dunskus

import Foundation
import Promise

typealias DownloadRequestPath<T: StoredObject> = WritableKeyPath<FileDownloadRequest, ObjectMeta<T>?>

struct FileDownloadRequest: JSONDataRequest {
	static let isIndependent = true
	
	var method: String { "file/download" }
	
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
	// max concurrent file downloads
	// (otherwise we start getting overrun with timeouts and overburderning the server)
	private static let downloadLimiter = DispatchSemaphore(value: 32)
	private static let waitQueue = DispatchQueue(label: "file download wait", qos: .userInitiated)
	
	func downloadFile<T: StoredObject>(for path: DownloadRequestPath<T>, meta: ObjectMeta<T>) -> Future<Data> {
		let quickResult = Self.downloadLimiter.wait(timeout: DispatchTime.now() + 0.01)
		switch quickResult {
		case .success:
			return downloadFileNow(for: path, meta: meta).always {
				Self.downloadLimiter.signal()
			}
		case .timedOut:
			return Future(asyncOn: Self.waitQueue) { promise in
				Self.downloadLimiter.wait()
				self.downloadFileNow(for: path, meta: meta)
					.always {
						Self.downloadLimiter.signal()
					}
					.then(promise.fulfill(with:))
					.catch(promise.reject(with:))
			}
		}
	}
	
	private func downloadFileNow<T: StoredObject>(for path: DownloadRequestPath<T>, meta: ObjectMeta<T>) -> Future<Data> {
		getUser()
			.map { user in
				FileDownloadRequest(
					authenticationToken: user.authenticationToken,
					requestingFileFor: path,
					meta: meta
				)
			}.flatMap(send)
	}
}
