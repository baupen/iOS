// Created by Julian Dunskus

import Foundation

let defaults = UserDefaults.standard

func registerDefaults() {
	defaults.register(
		defaults: [
			stayLoggedInKey: true,
		]
	)
}

fileprivate let stayLoggedInKey = "stayLoggedIn"
extension UserDefaults {
	var stayLoggedIn: Bool {
		get {
			return bool(forKey: stayLoggedInKey)
		}
		set {
			set(newValue, forKey: stayLoggedInKey)
		}
	}
}
