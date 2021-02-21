// Created by Julian Dunskus

import Foundation

struct APIIssue {
	let number: Int?
	let isMarked: Bool
	let wasAddedWithClient: Bool
	let description: String?
	let deadline: Date?
	
	let craftsman: Craftsman.ID?
	let map: Map.ID?
	
	let positionX: Double?
	let positionY: Double?
	let positionZoomScale: Double?
	
	let createdAt: Date
	let createdBy: ConstructionManager.ID
	let registeredAt: Date?
	let registeredBy: ConstructionManager.ID?
	let resolvedAt: Date?
	let resolvedBy: Craftsman.ID?
	let closedAt: Date?
	let closedBy: ConstructionManager.ID?
	
	let imageUrl: File<Issue>?
	
	func makeObject(meta: Issue.Meta, context: ConstructionSite.ID) -> Issue {
		Issue(
			meta: meta, constructionSiteID: context,
			mapID: map,
			number: number,
			wasAddedWithClient: wasAddedWithClient,
			deadline: deadline,
			position: positionX == nil ? nil
				: .init(at: Point(x: positionX!, y: positionY!), zoomScale: positionZoomScale!),
			isMarked: isMarked,
			description: description,
			craftsmanID: craftsman,
			status: .init(
				createdAt: createdAt,
				createdBy: createdBy,
				registeredAt: registeredAt,
				registeredBy: registeredBy,
				resolvedAt: resolvedAt,
				resolvedBy: resolvedBy,
				closedAt: closedAt,
				closedBy: closedBy
			),
			image: imageUrl,
			wasUploaded: true
		)
	}
}

extension APIIssue: APIModel {}
