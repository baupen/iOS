// Created by Julian Dunskus

import Foundation

struct User: APIObject {
	var meta: ObjectMeta
	var authenticationToken: String
	var givenName: String
	var familyName: String
	
	// TODO make non-optional once API updated
	var username: String!
	var passwordHash: String!
	
	var fullName: String {
		return "\(givenName) \(familyName)"
	}
}
