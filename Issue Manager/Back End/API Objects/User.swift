// Created by Julian Dunskus

import Foundation

struct LocalUser: Codable {
	var user: User
	
	/// the username typed in locally, before domain overrides
	var localUsername: String
	/// the username sent to the server, with domain overrides applied
	var username: String
	var passwordHash: String
	
	/// whether or not the user has explicitly logged out
	var hasLoggedOut = false
	
	init(user: User, localUsername: String, username: String, passwordHash: String) {
		self.user = user
		self.localUsername = localUsername
		self.username = username
		self.passwordHash = passwordHash
	}
}

struct User: APIObject {
	var meta: ObjectMeta<User>
	var authenticationToken: String
	var givenName: String
	var familyName: String
}

extension User {
	var fullName: String {
		return "\(givenName) \(familyName)"
	}
}

struct TrialUser: Codable {
	var username: String
	var password: String	
}
