// Created by Julian Dunskus

import Foundation

func encodeMultipartRequest(containing parts: [MultipartPart], into request: inout URLRequest) throws {
	let boundary = "boundary-\(UUID())-boundary"
	let rawBoundary = "--\(boundary)\r\n".data(using: .utf8)!
	
	request.setValue("multipart/form-data; charset=utf-8; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
	request.httpBody = try parts
		.lazy
		.map { try rawBoundary + $0.makeFormData() }
		.reduce(into: Data(), +=)
		+ "--\(boundary)--\r\n".data(using: .utf8)!
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
