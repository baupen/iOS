// Created by Julian Dunskus

import Foundation

struct LocalUser: Codable {
	var user: User
	
	/// the username sent to the server, with domain overrides applied
	var username: String
	var passwordHash: String
	
	/// whether or not the user has explicitly logged out
	var hasLoggedOut = false
}

struct User {
	var meta: ObjectMeta<User>
	var authenticationToken: String
	var givenName: String
	var familyName: String
	
	var fullName: String {
		"\(givenName) \(familyName)"
	}
}

extension User: StoredObject {}

struct TrialUser: Codable {
	var username: String
	var password: String	
}
