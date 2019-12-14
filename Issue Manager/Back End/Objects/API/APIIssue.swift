// Created by Julian Dunskus

import Foundation

struct APIIssue {
	let meta: ObjectMeta<Issue>
	let number: Int?
	let isMarked: Bool
	let wasAddedWithClient: Bool
	let image: File<Issue>?
	let description: String?
	let craftsman: ID<Craftsman>?
	let map: ID<Map>
	let status: Issue.Status
	let position: Issue.Position?
	
	var details: Issue.Details {
		.init(
			isMarked: isMarked,
			image: image,
			description: description,
			craftsman: craftsman
		)
	}
	
	func makeObject() -> Issue {
		Issue(
			meta: meta,
			number: number,
			wasAddedWithClient: wasAddedWithClient,
			mapID: map,
			position: position,
			status: status,
			details: details
		)
	}
}

extension APIIssue: APIModel {}

extension Issue {
	func makeModel() -> APIIssue {
		APIIssue(
			meta: meta,
			number: number,
			isMarked: isMarked,
			wasAddedWithClient: wasAddedWithClient,
			image: image,
			description: description,
			craftsman: craftsmanID,
			map: mapID,
			status: status,
			position: position
		)
	}
}
