// Created by Julian Dunskus

import Foundation

struct APIIssue {
	var number: Int?
	var isMarked: Bool
	var wasAddedWithClient: Bool
	var description: String?
	var deadline: Date?
	
	var craftsman: APICraftsman.ID?
	var map: APIMap.ID
	
	var positionX: Double?
	var positionY: Double?
	var positionZoomScale: Double?
	
	var createdAt: Date
	var createdBy: APIConstructionManager.ID
	var registeredAt: Date?
	var registeredBy: APIConstructionManager.ID?
	var resolvedAt: Date?
	var resolvedBy: APICraftsman.ID?
	var closedAt: Date?
	var closedBy: APIConstructionManager.ID?
	
	var imageUrl: File<Issue>?
	
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
