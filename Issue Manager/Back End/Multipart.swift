// Created by Julian Dunskus

import Foundation

func multipartRequest(to url: URL, parts: [MultipartPart]) throws -> URLRequest {
	let boundary = "boundary-\(UUID())-boundary"
	let rawBoundary = "--\(boundary)\r\n".data(using: .utf8)!
	
	let body = try parts
		.lazy
		.map { try rawBoundary + $0.makeFormData() }
		.reduce(into: Data(), +=)
		+ "--\(boundary)--\r\n".data(using: .utf8)!
	
	return URLRequest(url: url) <- {
		$0.httpMethod = "POST"
		$0.setValue("multipart/form-data; charset=utf-8; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		$0.httpBody = body
	}
}

struct MultipartPart {
	var name: String
	var content: Content
	
	func makeFormData() throws -> Data {
		let contentHeader: String
		if let header = content.header {
			contentHeader = "; \(header)"
		} else {
			contentHeader = ""
		}
		
		var data = """
			Content-Disposition: form-data; name="\(name)"\(contentHeader)\r
			Content-Type: \(content.type)\r
			\r
			
			""".data(using: .utf8)!
		
		switch content {
		case .json(let jsonData):
			data += jsonData
		case .jpeg(at: let url):
			data += try Data(contentsOf: url)
		}
		
		data += "\r\n".data(using: .utf8)!
		
		return data
	}
	
	enum Content {
		case json(Data)
		case jpeg(at: URL)
		
		var type: String {
			switch self {
			case .json:
				return "application/json"
			case .jpeg:
				return "image/jpeg"
			}
		}
		
		var header: String? {
			switch self {
			case .jpeg(let url):
				return "filename=\(url.lastPathComponent)"
			default:
				return nil
			}
		}
	}
}
