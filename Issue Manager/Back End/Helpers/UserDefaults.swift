// Created by Julian Dunskus

import Foundation

let defaults = UserDefaults.standard

fileprivate let isInClientModeKey = "isInClientMode"
fileprivate let stayLoggedInKey = "stayLoggedIn"
fileprivate let lastBuildingIDKey = "lastBuildingID"

func registerDefaults() {
	defaults.register(
		defaults: [
			stayLoggedInKey: true,
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
	
	var lastBuildingID: UUID? {
		get { return string(forKey: lastBuildingIDKey).flatMap(UUID.init) }
		set { set(lastBuildingID?.uuidString, forKey: lastBuildingIDKey) }
	}
}
