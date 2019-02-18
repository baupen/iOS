// Created by Julian Dunskus

import Foundation

extension Data {
	func sha256() -> Data {
		var result = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
		withUnsafeBytes { input in
			result.withUnsafeMutableBytes { output in
				_ = CC_SHA256(input, CC_LONG(count), output)
			}
		}
		return result
	}
	
	func hexEncodedString() -> String {
		return self
			.map { String(format: "%02x", $0) } // best way to get 0-padded hex string
			.joined()
	}
}

extension String {
	func sha256() -> String {
		let rawHash = self.data(using: .utf8)!.sha256()
		return rawHash.hexEncodedString()
	}
}
