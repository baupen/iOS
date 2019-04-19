// Created by Julian Dunskus

import Foundation

struct DBIssue {
	let id: UUID
	let lastChangeTime: Date
	
	let number: Int?
	let wasAddedWithClient: Bool
	let map: UUID
	let position: Issue.Position?
	let status: Issue.Status
	let details: Issue.Details
}

extension DBIssue: Codable {}

extension DBIssue: DBModel {
	func makeObject() -> Issue {
		return .init(
			meta: meta,
			number: number,
			wasAddedWithClient: wasAddedWithClient,
			map: .init(map),
			position: position,
			status: status,
			details: details
		)
	}
}

extension Issue: DBModelable {
	func makeModel() -> DBIssue {
		return .init(
			id: rawID,
			lastChangeTime: meta.lastChangeTime,
			number: number,
			wasAddedWithClient: wasAddedWithClient,
			map: map.rawValue,
			position: position,
			status: status,
			details: details
		)
	}
}
