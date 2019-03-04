// Created by Julian Dunskus

import Foundation

struct LocalUser: Codable {
	var user: User
	
	/// the username typed in locally, before domain overrides
	var localUsername: String
	/// the username sent to the server, with domain overrides applied
	var username: String
	var passwordHash: String	
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
