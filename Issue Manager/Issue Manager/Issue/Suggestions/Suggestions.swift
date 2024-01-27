// Created by Julian Dunskus

import Foundation
import Algorithms
import UserDefault
import HandyOperators

struct Suggestion: Codable {
	var text: String
	var occurrences = 0
	var lastUseTime = Date.now
	
	mutating func use() {
		occurrences += 1
		lastUseTime = Date()
	}
	
	mutating func decrement() {
		occurrences -= 1
	}
}

final actor SuggestionStorage {
	static let shared = SuggestionStorage()
	
	@UserDefault("suggestions")
	private static var rawSuggestions: Data?
	
	private static let defaultSuggestionsURL = Bundle.main.url(
		forResource: "default_suggestions", withExtension: "json"
	)!
	
	/// dictionary of suggestions for each trade
	private var storage: [String: [String: Suggestion]] {
		didSet { save() }
	}
	
	private static let decoder = JSONDecoder()
	private static let encoder = JSONEncoder()
	
	init() {
		storage = Self.load()
	}
	
	private static func load() -> [String: [String: Suggestion]] {
		do {
			let raw = try rawSuggestions ?? {
				print("Loading default suggestions…")
				return try Data(contentsOf: Self.defaultSuggestionsURL)
			}()
			
			do {
				return try decoder.decode(from: raw)
			} catch let outerError {
				// try to load the legacy format first
				return try (try? loadFromLegacyFormat(raw)) ??? outerError
			}
		} catch {
			error.printDetails(context: "Could not load suggestions!")
			return [:]
		}
	}
	
	private static func loadFromLegacyFormat(_ raw: Data) throws -> [String: [String: Suggestion]] {
		let legacy = try Self.decoder.decode([String: [Suggestion]].self, from: raw)
		return legacy.mapValues {
			Dictionary($0
				.lazy
				.filter { !$0.text.isEmpty }
				.map { ($0.text.lowercased(), $0) }
			) { $1 } // deduplicate: this should never happen but i'd rather not crash; suggestions aren't too valuable anyway
		}
	}
	
	func save() {
		do {
			let raw = try Self.encoder.encode(storage)
			Self.rawSuggestions = raw
			print("Suggestions saved!")
		} catch {
			error.printDetails(context: "Could not save suggestions!")
		}
	}
	
	/// - returns: up to `count` suggestions matching the given prefix, sorted by similarity of the `trade` param​eter to their trade and by occurrence count (descendingly) within a trade
	func suggestions(forTrade trade: String?, matching prefix: String?, count: Int) -> [Suggestion] {
		// sort trades by similarity to given trade, if applicable
		let prefix = prefix?.lowercased() ?? ""
		// all trades, sorted by similarity to given trade; most similar first
		let options = storage
			.sorted {
				guard let trade = trade?.lowercased() else { return true }
				// distance is cached anyway
				return $0.key.distance(to: trade) < $1.key.distance(to: trade)
			}
		
		var matches: [Suggestion] = []
		for (_, group) in options {
			let filtered = group.values
				.lazy
				.filter { $0.text.lowercased().hasPrefix(prefix) }
				.filter { option in !matches.contains(where: { $0.text == option.text }) } // no duplicates
				.max(count: count - matches.count) { $0.occurrences < $1.occurrences }
			matches.append(contentsOf: filtered)
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
	
	private func transformSuggestion(
		description: String?, forTrade trade: String?, 
		transform: (inout Suggestion) -> Void
	) {
		guard let description = description?.nonEmptyOptional else { return }
		
		transform(&storage[
			trade ?? "", default: [:]
		][
			description.lowercased(), default: Suggestion(text: description)
		])
	}
}
