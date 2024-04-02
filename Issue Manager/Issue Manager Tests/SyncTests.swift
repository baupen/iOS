// Created by Julian Dunskus

@testable import Issue_Manager
import XCTest
import HandyOperators

final class SyncTests: XCTestCase {
	@MainActor
	func testIssueLifecycleRequests() async throws {
		let context = try TestingContext()
		let (user, _, map) = context.setUpBasics()
		var issue = Issue(at: .init(at: .init(x: 1, y: 2), zoomScale: 3), in: map, by: user)
		
		try issue.storeMockImage()
		
		_ = issue.saveChanges(in: context.repository)
		let v1 = issue.patchIfChanged!
		
		try await context.server.expectRequest(of: IssueCreationRequest.self) { request in
			return .init(
				meta: .init(id: .init(rawValue: "asdf"), lastChangeTime: .now),
				model: .mocked(patch: request.body) <- {
					$0.number = 42
				}
			)
		} in: {
			// intentionally fail to upload image
			try await context.server.expectRequest(of: ImageUploadRequest.self) { request in
				throw ExpectedError()
			} in: {
				do {
					try await context.syncManager.pushLocalChanges()
					XCTFail("expected error")
				} catch RequestError.pushFailed(let errors) {
					XCTAssertEqual(errors.count, 1)
					XCTAssertEqual(errors.first!.stage, .imageUpload)
					XCTAssert(errors.first!.cause is ExpectedError)
				}
			}
		}
		
		// should reattempt image upload
		try await context.server.expectRequest(of: ImageUploadRequest.self) { request in
			throw ExpectedError()
		} in: {
			do {
				try await context.syncManager.pushLocalChanges()
				XCTFail("expected error")
			} catch RequestError.pushFailed {}
		}
		
		issue = context.repository.read(Issue.fetchOne)!
		issue.description = "changed"
		_ = issue.saveChanges(in: context.repository)
		
		try await context.server.expectRequest(of: IssuePatchRequest.self) { [issue] request in
			return .init(
				meta: .init(id: issue.id.modelID, lastChangeTime: .now),
				model: .mocked(patch: v1.makeModel()) <- {
					$0.apply(request.body)
					$0.imageUrl = .init(urlPath: "server_image.jpg")
				}
			)
		} in: {
			try await context.server.expectRequest(of: ImageUploadRequest.self) { request in
				"uploaded_\(UUID()).jpg"
			} in: {
				try await context.syncManager.pushLocalChanges()
			}
		}
		
		try await context.syncManager.pushLocalChanges() // should do nothing
		
		issue = context.repository.read(Issue.fetchOne)!
		issue.image = nil
		_ = issue.saveChanges(in: context.repository)
		
		try await context.server.expectRequest(of: DeletionRequest.self) { [issue] request in
			XCTAssertEqual(request.path, "\(issue.apiPath)/image")
		} in: {
			try await context.syncManager.pushLocalChanges()
		}
		
		try await context.syncManager.pushLocalChanges() // should do nothing
	}
	
	@MainActor
	func testIssueImageUpdate() async throws {
		let context = try TestingContext()
		let (user, _, map) = context.setUpBasics()
		var issue = Issue(at: .init(at: .init(x: 1, y: 2), zoomScale: 3), in: map, by: user)
		
		_ = issue.saveChanges(in: context.repository)
		let v1 = issue.patchIfChanged!
		
		try await context.server.expectRequest(of: IssueCreationRequest.self) { request in
			return .init(
				meta: .init(id: .init(rawValue: "asdf"), lastChangeTime: .now),
				model: .mocked(patch: request.body)
			)
		} in: {
			try await context.syncManager.pushLocalChanges()
		}
		
		issue.description = "changed"
		_ = issue.saveChanges(in: context.repository)
		
		try await context.server.expectRequest(of: IssueCreationRequest.self) { request in
			return .init(
				meta: .init(id: .init(rawValue: "asdf"), lastChangeTime: .now),
				model: .mocked(patch: v1.makeModel()) <- {
					$0.apply(request.body)
					$0.imageUrl = .init(urlPath: "changed.jpg")
				}
			)
		} in: {
			try await context.syncManager.pushLocalChanges()
		}
		
		issue = context.repository.read(Issue.fetchOne)!
		XCTAssertEqual(issue.image!.urlPath, "changed.jpg")
	}
	
	@MainActor
	func testRiskyRaceConditionRepeatedly() async throws {
		for i in 1...100 {
			print("running iteration \(i)")
			try await testRiskyRaceCondition()
		}
	}
	
	// this test recreates a previous race condition where an issue image might be saved to disk between when the currently-in-use issues are fetched and when the extant files are listed
	@MainActor
	func testRiskyRaceCondition() async throws {
		let context = try TestingContext()
		let (user, _, map) = context.setUpBasics()
		var issue = Issue(at: .init(at: .init(x: 1, y: 2), zoomScale: 3), in: map, by: user)
		
		// concurrently download, which runs the cleanup closure
		try FileManager.default.createDirectory(at: Issue.baseLocalFolder, withIntermediateDirectories: true)
		let concurrentTask = Task.detached(priority: .utility) {
			dispatchPrecondition(condition: .notOnQueue(.main))
			await Issue.moveDisusedFiles(in: context.repository)
		}
		
		try issue.storeMockImage()
		
		_ = issue.saveChanges(in: context.repository)
		print("saved to repo")
		
		try await Task.sleep(for: .seconds(0.1))
		_ = try Data(contentsOf: Issue.localURL(for: issue.image!))
		
		_ = await concurrentTask.result
	}
	
	override class func tearDown() {
		wipeDownloadedFiles()
	}
}

extension Issue {
	mutating func storeMockImage() throws {
		let file = File<Issue>(urlPath: "/local/test_\(UUID()).jpg")
		let image = UIImage(systemName: "questionmark")!
		try image.saveJPEG(to: Self.localURL(for: file))
		self.image = file
	}
}
