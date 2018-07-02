// Created by Julian Dunskus

import Foundation

let defaults = UserDefaults.standard

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
	var stayLoggedIn: Bool {
		get {
			return bool(forKey: stayLoggedInKey)
		}
		set {
			set(newValue, forKey: stayLoggedInKey)
		}
	}
	
	var lastBuildingID: UUID? {
		get {
			return string(forKey: lastBuildingIDKey).flatMap(UUID.init)
		}
		set {
			set(lastBuildingID?.uuidString, forKey: lastBuildingIDKey)
		}
	}
}
