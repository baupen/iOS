// Created by Julian Dunskus

import Foundation

struct LocalUser: Codable {
	var user: User
	var username: String!
	var passwordHash: String!	
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
