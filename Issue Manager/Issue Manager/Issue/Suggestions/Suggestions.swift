// Created by Julian Dunskus

import Foundation
import UserDefault

final class Suggestion: Codable {
	var text: String
	var occurrences: Int
	var lastUseTime: Date
	
	init(text: String) {
		self.text = text
		self.occurrences = 0
		self.lastUseTime = Date()
	}
	
	func use() {
		occurrences += 1
		lastUseTime = Date()
	}
	
	func decrement() {
		occurrences -= 1
	}
}

final class SuggestionStorage {
	static let shared = SuggestionStorage()
	
	@UserDefault("suggestions")
	private static var rawSuggestions: Data?
	
	private var storage: [String: [Suggestion]] {
		didSet { save() }
	}
	
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()
	
	init() {
		do {
			let raw: Data
			if let data = Self.rawSuggestions {
				raw = data
			} else {
				print("Loading default suggestions…")
				let path = Bundle.main.path(forResource: "default_suggestions", ofType: "json")!
				raw = try Data(contentsOf: URL(fileURLWithPath: path))
			}
			
			storage = try decoder.decode(from: raw)
			print("Suggestions loaded!")
		} catch {
			storage = [:]
			error.printDetails(context: "Could not load suggestions!")
		}
	}
	
	private let savingQueue = DispatchQueue(label: "suggestions saving")
	func save() {
		savingQueue.async { [storage] in
			do {
				let raw = try self.encoder.encode(storage)
				Self.rawSuggestions = raw
				print("Suggestions saved!")
			} catch {
				error.printDetails(context: "Could not save suggestions!")
			}
		}
	}
	
	/// - returns: up to `count` suggestions matching the given prefix, sorted by similarity of the `trade` param​eter to their trade and by occurrence count (descendingly) within a trade
	func suggestions(forTrade trade: String?, matching prefix: String?, count: Int) -> [Suggestion] {
		// sort trades by similarity to given trade, if applicable
		let options: [[Suggestion]]
		if let trade = trade?.lowercased() {
			// all trades, sorted by similarity to given trade; most similar first
			options = storage
				.map { (distance: $0.key.distance(to: trade), suggestions: $0.value) }
				.sorted { $0.distance < $1.distance }
				.map { $0.suggestions }
		} else {
			// fall back on all values
			options = Array(storage.values)
		}
		
		// only use suggestions matching the prefix, if applicable
		let filtered: AnyCollection<[Suggestion]>
		if let prefix = prefix?.nonEmptyOptional?.lowercased() {
			filtered = AnyCollection(options
				.lazy
				.map { $0.filter { $0.text.lowercased().hasPrefix(prefix) && !$0.text.isEmpty } }
			)
		} else {
			filtered = AnyCollection(options)
		}
		
		var matches: [Suggestion] = []
		for group in filtered {
			matches.append(
				contentsOf: group
					.filter { option in !matches.contains(where: { $0.text == option.text }) } // no duplicates
					.max(count - matches.count, by: { $0.occurrences < $1.occurrences })
			)
			guard matches.count < count else {
				break // done
			}
		}
		return matches
	}
	
	func used(description: String?, forTrade trade: String?) {
		transformSuggestion(description: description, forTrade: trade) { $0.use() }
	}
	
	func decrementSuggestion(description: String?, forTrade trade: String?) {
		transformSuggestion(description: description, forTrade: trade) { $0.decrement() }
	}
	
	private func transformSuggestion(description: String?, forTrade trade: String?, transform: (Suggestion) -> Void) {
		guard let description = description?.nonEmptyOptional else { return }
		
		let tradeKey = trade ?? ""
		
		let suggestion = storage[tradeKey]?.first { $0.text.lowercased() == description.lowercased() }
			?? (Suggestion(text: description) <- { storage[tradeKey, default: []].append($0) })
		transform(suggestion)
		
		save()
	}
}
