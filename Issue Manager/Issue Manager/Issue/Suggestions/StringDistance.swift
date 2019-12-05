// Copied from https://gist.github.com/automactic/f8e1d26c3c23ddbc5b8c2151f119d663 and slightly adjusted

import Foundation

private func key(_ a: Substring, _ b: Substring) -> String {
	"\(a)§\(b)"
}

private final class Levenshtein {
	private(set) var cache: [String: Int] = [:]
	
	func calculateDistance(_ a: Substring, _ b: Substring) -> Int {
		if let distance = cache[key(a, b)] ?? cache[key(b, a)] {
			return distance
		} else {
			let distance: Int
			if a.isEmpty || b.isEmpty {
				distance = a.count + b.count
			} else if a.first == b.first {
				distance = calculateDistance(a.dropFirst(), b.dropFirst())
			} else {
				let add = calculateDistance(a, b.dropFirst())
				let replace = calculateDistance(a.dropFirst(), b.dropFirst())
				let delete = calculateDistance(a.dropFirst(), b)
				distance = min(add, replace, delete) + 1
			}
			
			cache[key(a, b)] = distance
			return distance
		}
	}
}

extension String {
	func distance(to other: String) -> Int {
		Levenshtein().calculateDistance(Substring(self), Substring(other))
	}
}
