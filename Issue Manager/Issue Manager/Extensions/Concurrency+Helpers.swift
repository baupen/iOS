import Foundation

extension Result where Failure == Never {
	var value: Success {
		switch self { case .success(let value): value }
	}
}

extension Task<Never, Never> {
	static func sleep(forSeconds seconds: TimeInterval) async throws {
		try await sleep(nanoseconds: UInt64(seconds * 1e9))
	}
}

// TODO: avoid/remove this once we get Region-Based Isolation (https://forums.swift.org/t/pitch-region-based-isolation/67888)
/// This wrapper is safe when used to transfer (non-Sendable) values that were freshly constructed so this is the only reference to them, or when a value really is Sendable in the current context (e.g. notifications passed to a main actor isolated task)
struct UncheckedSendable<Value>: @unchecked Sendable {
	var value: Value
	
	init(_ value: Value) {
		self.value = value
	}
}

/// This wrapper allows you to mutate a value when you know it's safe but cannot express this in the type system (yet!), e.g. for progress callbacks that are completely serial.
final class UncheckedMutableSendable<Value>: @unchecked Sendable {
	var value: Value
	
	init(_ value: Value) {
		self.value = value
	}
}

extension Sequence where Element: Sendable {
	func concurrentForEach(
		slots: Int = .max,
		running block: @escaping @Sendable (Element) async throws -> Void,
		onProgress: () -> Void
	) async throws {
		try await withThrowingTaskGroup(of: Void.self) { group in
			var remainingSlots = slots
			for element in self {
				if remainingSlots > 0 {
					remainingSlots -= 1
				} else {
					// wait for one previous task to complete before starting a new one
					try await group.next()
					onProgress()
				}
				
				try Task.checkCancellation()
				group.addTask {
					try await block(element)
				}
			}
			
			while try await group.next() != nil {
				onProgress()
			}
		}
	}
}
