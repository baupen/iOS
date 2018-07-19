// Created by Julian Dunskus

import Foundation

struct User: APIObject {
	var meta: ObjectMeta
	var authenticationToken: String
	var givenName: String
	var familyName: String
	
	// set by request, not API
	var username: String!
	var passwordHash: String!
}

extension User {
	var fullName: String {
		return "\(givenName) \(familyName)"
	}
}
