// Created by Julian Dunskus

import Foundation

typealias TaskResult = (data: Data, response: HTTPURLResponse)

class Client {
	static let shared = Client()
	
	private static let baseURL = URL(string: "https://dev.app.mangel.io/api")!
	
	private let urlSession = URLSession.shared
	
	private let requestEncoder = JSONEncoder() <- {
		$0.dateEncodingStrategy = .iso8601
	}
	private let responseDecoder = JSONDecoder() <- {
		$0.dateDecodingStrategy = .iso8601
	}
	
	var user: User?
	var storage = Storage()
	// TODO build up backlog rather than attempting requests once reachability is implemented
	private var backlog: [BacklogStorable] = []
	private var isClearingBacklog = false // oh no
	
	private let backlogQueue = DispatchQueue(label: "backlog clearing")
	
	private init() {
		loadShared()
	}
	
	func addToBacklog(_ request: BacklogStorable) {
		guard !isClearingBacklog else { return }
		backlogQueue.async {
			self.backlog.append(request)
		}
	}
	
	func clearBacklog() -> Future<Void> {
		isClearingBacklog = true
		return Future { promise in
			backlogQueue.async {
				let group = DispatchGroup()
				
				for (index, request) in self.backlog.enumerated() {
					group.enter()
					let result = request.send()
					result.always(group.leave)
					
					var cancelCause: RequestError?
					
					result.then { _ in 
						print("backlog request \(request.method) cleared successfully")
					}
					
					result.catch { error in
						if case RequestError.communicationError(let error) = error {
							print("backlog request \(request.method) failed with a communication error! cancelling...")
							cancelCause = .communicationError(error)
						} else {
							print("backlog request \(request.method) failed! clearing anyway.")
						}
					}
					
					group.wait()
					
					if let error = cancelCause {
						self.backlog.removeFirst(index) // remove all previously completed tasks
						promise.reject(with: error)
						return
					}
				}
				
				self.backlog = []
				promise.fulfill()
			}
			}
			.always { self.isClearingBacklog = false }
	}
	
	func send<R: MultipartJSONRequest>(_ request: R) -> Future<R.ExpectedResponse> {
		return Future.fulfilled(with: request)
			.map { request in
				let encoded = try self.requestEncoder.encode(request)
				let parts = [MultipartPart(name: "message", content: .json(encoded))]
					+ (request.fileURL.map { [MultipartPart(name: "image", content: .jpeg(at: $0))] } ?? [])
				return try multipartRequest(to: self.apiURL(for: request), parts: parts)
			}
			.flatMap(send)
			.map(extractData)
			.map(decodeResponse)
	}
	
	func send<R: JSONJSONRequest>(_ request: R) -> Future<R.ExpectedResponse> {
		return sendBasic(request)
			.map(decodeResponse)
	}
	
	func send<R: JSONDataRequest>(_ request: R) -> Future<Data> {
		return sendBasic(request)
	}
	
	private func sendBasic<R: DataRequest>(_ request: R) -> Future<Data> {
		return Future.fulfilled(with: request)
			.map(urlRequest)
			.flatMap(send)
			.map(extractData)
	}
	
	private func decodeResponse<R: Response>(from data: Data) throws -> R {
		let success = try responseDecoder.decode(JSendSuccess<R>.self, from: data)
		print("Decoded response!")
		return success.data
	}
	
	private func extractData(from taskResult: TaskResult) throws -> Data {
		let (data, response) = taskResult
		print("Status code: \(response.statusCode), body: \(debugRepresentation(of: data))")
		switch response.statusCode {
		case 200:
			return data
		case 400:
			let failure = try self.responseDecoder.decode(JSendFailure.self, from: data)
			throw RequestError.apiError(failure)
		case 500:
			let error = try self.responseDecoder.decode(JSendError.self, from: data)
			throw RequestError.serverError(error)
		case let code:
			fatalError("Invalid status code \(code)")
		}
	} 
	
	private func urlRequest<R: DataRequest>(body: R) throws -> URLRequest {
		return try URLRequest(url: apiURL(for: body)) <- {
			$0.httpMethod = "POST"
			$0.httpBody = try requestEncoder.encode(body)
		}
	}
	
	private func apiURL<R: DataRequest>(for request: R) -> URL {
		return Client.baseURL.appendingPathComponent(request.method)
	}
	
	private func send(_ request: URLRequest) -> Future<TaskResult> {
		let path = request.url!.relativePath
		print("\(path): Sending \(debugRepresentation(of: request.httpBody!))")
		return urlSession.dataTask(with: request)
			.mapError(RequestError.communicationError)
			.always { print("\(path): Received response") }
	}
}

/// An error that occurs while interfacing with the server.
enum RequestError: Error {
	/// You tried to do something that requires authentication without being authenticated.
	case notAuthenticated
	/// An error occurred during communication with the server. Likely causes include an unstable internet connection and the server being down.
	case communicationError(Error)
	/// The server didn't fulfill the request because something was wrong with it.
	case apiError(JSendFailure)
	/// The server encountered an error whilst fulfilling the request.
	case serverError(JSendError)
}

fileprivate func debugRepresentation(of data: Data, maxLength: Int = 500) -> String {
	guard data.count <= maxLength else { return "<\(data.count) bytes>" }
	
	return String(bytes: data, encoding: .utf8)?
		.replacingOccurrences(of: "\n", with: "\\n")
		.replacingOccurrences(of: "\r", with: "\\r")
		?? "<\(data.count) bytes not UTF-8 decodable data>"
}

// MARK: -
// MARK: Saving & Loading

extension Client {
	func loadShared() {
		let defaults = UserDefaults.standard
		do {
			user = try defaults.decode(forKey: "Client.shared.user")
			storage = try defaults.decode(forKey: "Client.shared.storage") ?? storage
			print("Client loaded!")
		} catch {
			print("Client could not be loaded!")
			print(error.localizedDescription)
			print(error)
		}
	}
	
	func saveShared() {
		let defaults = UserDefaults.standard
		do {
			try defaults.encode(user, forKey: "Client.shared.user")
			try defaults.encode(storage, forKey: "Client.shared.storage")
			print("Client saved!")
		} catch {
			print("Client could not be saved!")
			print(error.localizedDescription)
			print(error)
		}
	}
}
