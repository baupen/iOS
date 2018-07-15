// Created by Julian Dunskus

import Foundation

struct Suggestion: Codable {
	var text: String
	var occurrences: Int
	var lastUseTime: Date
	
	init(text: String) {
		self.text = text
		self.occurrences = 1
		self.lastUseTime = Date()
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
			#if DEBUG
			storage["Hochbauzeichner"] = [
				Suggestion(text: "Unebene oberfläche"),
				Suggestion(text: "Zu ebene Oberfläche!"),
				Suggestion(text: "Unebene unterfläche :p"),
				Suggestion(text: "Unantastbares Problem"),
			]
			#endif
			print("Suggestions loaded!")
		} catch {
			storage = [:]
			print("Could not load suggestions!", error.localizedDescription)
			dump(error)
		}
	}
	
	private let savingQueue = DispatchQueue(label: "suggestions saving")
	func save() {
		let storage = self.storage
		savingQueue.async {
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
	
	func suggestions(forTrade trade: String?, matching prefix: String?) -> [Suggestion] {
		let options = trade
			.flatMap { storage[$0].map(AnyCollection.init) } // specific values if available
			?? AnyCollection(storage.lazy.flatMap { $0.value }) // fall back on all values
		
		let unsorted: AnyCollection<Suggestion>
		if let prefix = prefix {
			let lowercasedPrefix = prefix.lowercased()
			unsorted = AnyCollection(options
				.lazy
				.filter { $0.text.lowercased().hasPrefix(lowercasedPrefix) }
				.prefix(SuggestionsHandler.suggestionCount)
			)
		} else {
			unsorted = AnyCollection(options.prefix(SuggestionsHandler.suggestionCount))
		}
		
		return unsorted.sorted { $0.occurrences > $1.occurrences }
	}
}
