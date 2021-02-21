// Created by Julian Dunskus

import Foundation

let defaults = UserDefaults.standard

// TODO: use @UserDefault instead of this mess

fileprivate let isInClientModeKey = "isInClientMode"
fileprivate let stayLoggedInKey = "stayLoggedIn"
fileprivate let hiddenStatusesKey = "hiddenStatuses"
fileprivate let suggestionsKey = "suggestions"
fileprivate let useFakeReadResponseKey = "useFakeReadResponse"
fileprivate let hasTakenPhotoKey = "hasTakenPhoto"
fileprivate let trialUserKey = "trialUser"
fileprivate let lastWipeVersionKey = "lastWipeVersion"

func registerDefaults() {
	defaults.register(
		defaults: [
			isInClientModeKey: false,
			stayLoggedInKey: true,
			hiddenStatusesKey: [],
			hasTakenPhotoKey: false,
		]
	)
}

extension UserDefaults {
	var lastWipeVersion: Int {
		get { integer(forKey: lastWipeVersionKey) }
		set { set(newValue, forKey: lastWipeVersionKey) }
	}
	
	/// issues recorded in client mode are marked as such; other issues should not be displayed whilst in client mode
	var isInClientMode: Bool {
		get { bool(forKey: isInClientModeKey) }
		set { set(newValue, forKey: isInClientModeKey) }
	}
	
	var stayLoggedIn: Bool {
		get { bool(forKey: stayLoggedInKey) }
		set { set(newValue, forKey: stayLoggedInKey) }
	}
	
	// inverted to make new statuses shown by default
	var hiddenStatuses: [Issue.Status.Simplified] {
		get {
			let raw = object(forKey: hiddenStatusesKey) as? [Issue.Status.Simplified.RawValue] ?? []
			return raw.compactMap(Issue.Status.Simplified.init)
		}
		set {
			let raw = newValue.map { $0.rawValue }
			set(raw, forKey: hiddenStatusesKey)
		}
	}
	
	var rawSuggestions: Data? {
		get { data(forKey: suggestionsKey) }
		set { set(newValue, forKey: suggestionsKey) }
	}
	
	/// used to fake sector data before they're added to the API; specified in the Xcode scheme's argument overrides
	var useFakeReadResponse: Bool {
		bool(forKey: useFakeReadResponseKey)
	}
	
	var hasTakenPhoto: Bool {
		get { bool(forKey: hasTakenPhotoKey) }
		set { set(newValue, forKey: hasTakenPhotoKey) }
	}
	
	var trialUser: TrialUser? {
		get {
			data(forKey: trialUserKey).map { try! JSONDecoder().decode(from: $0) }
		}
		set {
			set(try! JSONEncoder().encode(newValue), forKey: trialUserKey)
		}
	}
}
