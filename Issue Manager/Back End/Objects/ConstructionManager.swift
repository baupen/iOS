// Created by Julian Dunskus

import Foundation

struct LocalUser: Codable {
	var manager: ConstructionManager
	var id: ConstructionManager.ID { manager.id }
	
	/// the username sent to the server, with domain overrides applied
	var username: String
	var passwordHash: String
	
	/// whether or not the user has explicitly logged out
	var hasLoggedOut = false
}

struct ConstructionManager: Codable {
	var meta: Meta
	var authenticationToken: String?
	var givenName: String
	var familyName: String
	
	var fullName: String {
		"\(givenName) \(familyName)"
	}
}

extension ConstructionManager: StoredObject {
	static let apiType = "construction_managers"
}

struct TrialUser: Codable {
	var username: String
	var password: String	
}
