import Foundation

// just closures with some nice helpers
// a little overengineered but fundamentally simple and not prone to bugs, moving complexity out of the actual "meat" of the sync/download tasks
enum ProgressHandler<Progress> {
	case onMainActor(@MainActor @Sendable (Progress) -> Void)
	case unisolated(Unisolated)
	
	static var ignore: Self { .unisolated(.init()) }
	
	struct Unisolated {
		var onProgress: (@Sendable (Progress) -> Void)?
		
		func callAsFunction(_ progress: Progress) {
			onProgress?(progress)
		}
		
		func wrapped<OtherProgress>(
			translate: @escaping @Sendable (OtherProgress) -> Progress
		) -> ProgressHandler<OtherProgress> {
			.unisolated(wrapped(translate: translate))
		}
		
		@_disfavoredOverload
		func wrapped<OtherProgress>(
			translate: @escaping @Sendable (OtherProgress) -> Progress
		) -> ProgressHandler<OtherProgress>.Unisolated {
			// eking out that unnecessary efficiency
			.init(onProgress: onProgress.map { onProgress in
				{ @Sendable in onProgress(translate($0)) }
			})
		}
	}
	
	/// provides an unisolated callback whose values will get forwarded to the main actor-isolated underlying handler without reordering
	func unisolated<Result>(
		@_inheritActorContext run block: @Sendable (
			_ onProgress: ProgressHandler<Progress>.Unisolated
		) async throws -> Result
	) async throws -> Result where Progress: Sendable {
		switch self {
		case .onMainActor(let onProgress):
			try await AsyncStream<Progress>.withStream { yield in
				try await block(.init(onProgress: yield))
			} readStream: { @MainActor in
				for await progress in $0 {
					onProgress(progress)
				}
			}
		case .unisolated(let onProgress):
			try await block(onProgress)
		}
	}
}

private extension AsyncStream {
	static func withStream<Result>(
		@_inheritActorContext run block: @Sendable (
			_ yield: @escaping @Sendable (Element) -> Void
		) async throws -> Result,
		@_inheritActorContext readStream: @Sendable (AsyncStream<Element>) async throws -> Void
	) async throws -> Result {
		let (stream, continuation) = AsyncStream.makeStream(of: Element.self)
		async let result = try await {
			defer { continuation.finish() }
			return try await block {
				continuation.yield($0)
			}
		}()
		try await readStream(stream)
		return try await result
	}
}
