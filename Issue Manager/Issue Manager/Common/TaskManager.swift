// TODO: once we get the ability to inherit the caller's actor isolation, we can get rid of the @MainActor requirements all over
// more at https://forums.swift.org/t/pitch-inheriting-the-callers-actor-isolation/68391

/// Lets one task run at a time, with some tracking features.
@MainActor
final class TaskManager<Success: Sendable, Failure: Error> {
	private(set) var currentTask: Task<Success, Failure>?
	
	var isBusy: Bool { currentTask != nil }
	
	private var queueCounter = 0
	
	/// Waits for there to be no running task, then runs the given task if this method hasn't been called again in the meantime.
	/// - Returns: ``block``'s return value, if it ran, otherwise that of the block running when called.
	func runIfNewest(
		block: @escaping @MainActor () async -> Success
	) async -> Success where Failure == Never {
		await runIfNewest {
			Task { await block() }
		}.value
	}
	
	/// Waits for there to be no running task, then runs the given task if this method hasn't been called again in the meantime.
	/// - Returns: ``block``'s return value, if it ran, otherwise that of the block running when called.
	func runIfNewest(
		block: @escaping @MainActor () async throws -> Success
	) async throws -> Success where Failure == any Error {
		try await runIfNewest {
			Task { try await block() }
		}.get()
	}
	
	func runIfNewest(
		makeTask: () -> Task<Success, Failure>
	) async -> Result<Success, Failure> {
		while let currentTask {
			queueCounter += 1
			let queueIndex = queueCounter
			let old = await currentTask.result
			guard queueIndex == queueCounter else {
				return old // already enqueued a newer version
			}
			if self.currentTask == currentTask { // might resume here before the defer block below
				self.currentTask = nil
			}
		}
		assert(currentTask == nil)
		
		let task = makeTask()
		currentTask = task
		defer {
			if currentTask == task { // not guaranteed that this is the first place to continue execution once the task finishes
				currentTask = nil
			}
		}
		return await task.result
	}
}
