// Created by Julian Dunskus

import Foundation

struct User: APIObject {
	var meta: ObjectMeta
	var authenticationToken: String
	var givenName: String
	var familyName: String
	
	var fullName: String {
		return "\(givenName) \(familyName)"
	}
}
