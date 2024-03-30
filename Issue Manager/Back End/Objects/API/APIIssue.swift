// Created by Julian Dunskus

import Foundation

struct APIIssue {
	let number: Int?
	let isMarked: Bool
	let wasAddedWithClient: Bool
	let description: String?
	let deadline: Date?
	
	let craftsman: APICraftsman.ID?
	let map: APIMap.ID
	
	let positionX: Double?
	let positionY: Double?
	let positionZoomScale: Double?
	
	let createdAt: Date
	let createdBy: APIConstructionManager.ID
	let registeredAt: Date?
	let registeredBy: APIConstructionManager.ID?
	let resolvedAt: Date?
	let resolvedBy: APICraftsman.ID?
	let closedAt: Date?
	let closedBy: APIConstructionManager.ID?
	
	let imageUrl: File<Issue>?
	
	func makeObject(meta: Issue.Meta, context: ConstructionSite.ID) -> Issue {
		Issue(
			meta: meta, constructionSiteID: context,
			mapID: map.makeID(),
			number: number,
			wasAddedWithClient: wasAddedWithClient,
			deadline: deadline,
			position: positionX == nil ? nil
				: .init(at: Point(x: positionX!, y: positionY!), zoomScale: positionZoomScale!),
			isMarked: isMarked,
			description: description,
			craftsmanID: craftsman?.makeID(),
			status: .init(
				createdAt: createdAt,
				createdBy: createdBy.makeID(),
				registeredAt: registeredAt,
				registeredBy: registeredBy?.makeID(),
				resolvedAt: resolvedAt,
				resolvedBy: resolvedBy?.makeID(),
				closedAt: closedAt,
				closedBy: closedBy?.makeID()
			),
			image: imageUrl,
			wasUploaded: true
		)
	}
}

extension APIIssue: APIModel {}
