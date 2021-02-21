// Created by Julian Dunskus

import Foundation
import Promise

/// Limits concurrent operations of a certain type
struct ConcurrencyLimiter {
	let semaphore: DispatchSemaphore
	let waitQueue: DispatchQueue
	
	init(label: String, maxConcurrency: Int) {
		self.semaphore = .init(value: 32)
		self.waitQueue = .init(label: "\(label) wait", qos: .userInitiated)
	}
	
	func dispatch<T>(_ task: @escaping () -> Future<T>) -> Future<T> {
		switch semaphore.wait(timeout: .now() + 0.01) {
		case .success:
			return task()
				.always { semaphore.signal() }
		case .timedOut:
			return Future(asyncOn: waitQueue) { promise in
				semaphore.wait()
				task()
					.always { semaphore.signal() }
					.then(promise.fulfill(with:))
					.catch(promise.reject(with:))
			}
		}
	}
}
