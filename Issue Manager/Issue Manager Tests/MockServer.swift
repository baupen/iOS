// Created by Julian Dunskus

@testable import Issue_Manager
import XCTest

actor MockServer {
	typealias Handler = @Sendable (any BaupenRequest) async throws -> any Sendable
	
	// keyed by mangled type name
	private var expectations: [String: Expectation] = [:]
	
	deinit {
		for expectation in expectations.values {
			expectation.fail()
		}
	}
	
	func expectRequest<R: BaupenRequest>(
		of type: R.Type = R.self,
		file: StaticString = #filePath, line: UInt = #line,
		handle: @escaping @Sendable (R) async throws -> R.Response
	) {
		guard expectations[R.key] == nil else {
			fatalError("already expecting request of type \(R.self)")
		}
		expectations[R.key] = .init(
			description: "expecting request of type \(R.self)",
			file: file, line: line,
			handle: { try await handle($0 as! R) }
		)
	}
	
	/// This takes a closure after which it asserts the request is done.
	// Swift concurrency in its current state makes that unwieldy (forcing us to make it @Sendable or the whole thing @MainActor).
	// TODO: @isolated(any) should fix this in future i think?
	@MainActor
	func expectRequest<R: BaupenRequest>(
		of type: R.Type = R.self,
		file: StaticString = #filePath, line: UInt = #line,
		handle: @escaping @Sendable (R) async throws -> R.Response,
		in block: () async throws -> Void
	) async rethrows {
		await expectRequest(of: type, file: file, line: line, handle: handle)
		try await block()
		await expectRequestDone(type)
	}
	
	func expectRequestDone<R: BaupenRequest>(_ type: R.Type) {
		expectations.removeValue(forKey: R.key)?.fail()
	}
	
	func handle<R: BaupenRequest>(_ request: R) async throws -> R.Response {
		guard let expectation = expectations.removeValue(forKey: R.key) else {
			throw CommunicationError.unexpectedRequest(R.self)
		}
		return try await expectation.handle(request) as! R.Response
	}
	
	struct Expectation: Sendable {
		let description: String
		let file: StaticString
		let line: UInt
		let handle: Handler
		
		func fail() {
			XCTFail(description, file: file, line: line)
		}
	}
	
	struct Context: RequestContext {
		let client: Client
		let loginInfo: LoginInfo?
		let server: MockServer
		
		func send<R: BaupenRequest>(_ request: R) async throws -> R.Response {
			try await server.handle(request)
		}
	}
	
	enum CommunicationError: Error {
		case unexpectedRequest(_ type: any BaupenRequest.Type)
	}
}

private extension BaupenRequest {
	static var key: String { _mangledTypeName(self)! }
}
