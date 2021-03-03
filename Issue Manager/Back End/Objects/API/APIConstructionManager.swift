// Created by Julian Dunskus

import Foundation

struct APIConstructionManager {
	var authenticationToken: String?
	var givenName: String?
	var familyName: String?
	
	func makeObject(meta: ConstructionManager.Meta, context: Void) -> ConstructionManager {
		ConstructionManager(
			meta: meta,
			authenticationToken: authenticationToken,
			givenName: givenName,
			familyName: familyName
		)
	}
}

extension APIConstructionManager: APIModel {}
