// Created by Julian Dunskus

import Foundation

final class Suggestion: Codable {
	var text: String
	var occurrences: Int
	var lastUseTime: Date
	
	init(text: String) {
		self.text = text
		self.occurrences = 1
		self.lastUseTime = Date()
	}
	
	func use() {
		occurrences += 1
		lastUseTime = Date()
	}
}

class SuggestionStorage {
	static let shared = SuggestionStorage()
	
	private var storage: [String: [Suggestion]] {
		didSet {
			save()
		}
	}
	
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()
	
	init() {
		do {
			let raw: Data
			if let data = defaults.rawSuggestions {
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
			print("Could not load suggestions!", error.localizedDescription)
			dump(error)
		}
	}
	
	private let savingQueue = DispatchQueue(label: "suggestions saving")
	func save() {
		savingQueue.async { [storage] in
			do {
				let raw = try self.encoder.encode(storage)
				defaults.rawSuggestions = raw
				print("Suggestions saved!")
			} catch {
				print("Could not save suggestions!", error.localizedDescription)
				dump(error)
			}
		}
	}
	
	/// - returns: up to `count` suggestions matching the given prefix, sorted by similarity of the `trade` parameter to their trade and by occurrence count (descendingly) within a trade
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
			options = [storage.values.flatMap { $0 }]
		}
		
		// only use suggestions matching the prefix, if applicable
		let filtered: AnyCollection<[Suggestion]>
		if let prefix = prefix?.lowercased() {
			filtered = AnyCollection(options
				.lazy
				.map { $0.filter { $0.text.lowercased().hasPrefix(prefix) } }
			)
		} else {
			filtered = AnyCollection(options)
		}
		
		// only the first few elements
		return Array(filtered
			.lazy
			.flatMap { $0.max(count, by: { $0.occurrences < $1.occurrences }) }
			.prefix(count)
		)
	}
	
	func used(description: String?, forTrade trade: String?) {
		guard let description = description else { return }
		
		let tradeKey = trade ?? ""
		
		let previous = storage[tradeKey]?.first { $0.text.lowercased() == description.lowercased() }
		if let previous = previous {
			previous.occurrences += 1
			previous.lastUseTime = Date()
		} else {
			storage[tradeKey, default: []].append(Suggestion(text: description))
		}
		
		save()
	}
}
