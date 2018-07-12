// Created by Julian Dunskus

import Foundation

let defaults = UserDefaults.standard

fileprivate let isInClientModeKey = "isInClientMode"
fileprivate let stayLoggedInKey = "stayLoggedIn"
fileprivate let hiddenStatusesKey = "hiddenStatuses"

func registerDefaults() {
	defaults.register(
		defaults: [
			isInClientModeKey: false,
			stayLoggedInKey: true,
			hiddenStatusesKey: [],
		]
	)
}

extension UserDefaults {
	/// issues recorded in client mode are marked as such; other issues should not be displayed whilst in client mode
	var isInClientMode: Bool {
		get { return bool(forKey: isInClientModeKey) }
		set { set(newValue, forKey: isInClientModeKey) }
	}
	
	var stayLoggedIn: Bool {
		get { return bool(forKey: stayLoggedInKey) }
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
}
