// Created by Julian Dunskus

@testable import Issue_Manager
import Foundation
import HandyOperators

extension APIIssue {
	static func mocked(
		number: Int? = nil,
		isMarked: Bool = false,
		wasAddedWithClient: Bool = false,
		description: String? = nil,
		deadline: Date? = nil,
		craftsman: APICraftsman.ID? = nil,
		map: APIMap.ID,
		positionX: Double? = nil, positionY: Double? = nil, positionZoomScale: Double? = nil,
		createdAt: Date = .now, createdBy: APIConstructionManager.ID,
		registeredAt: Date? = nil, registeredBy: APIConstructionManager.ID? = nil,
		resolvedAt: Date? = nil, resolvedBy: APICraftsman.ID? = nil,
		closedAt: Date? = nil, closedBy: APIConstructionManager.ID? = nil,
		imageUrl: File<Issue>? = nil
	) -> Self {
		.init(
			number: number,
			isMarked: isMarked,
			wasAddedWithClient: wasAddedWithClient,
			description: description,
			deadline: deadline,
			craftsman: craftsman,
			map: map,
			positionX: positionX, positionY: positionY, positionZoomScale: positionZoomScale,
			createdAt: createdAt, createdBy: createdBy,
			registeredAt: registeredAt, registeredBy: registeredBy,
			resolvedAt: resolvedAt, resolvedBy: resolvedBy,
			closedAt: closedAt, closedBy: closedBy,
			imageUrl: imageUrl
		)
	}
	
	static func mocked(patch: APIIssuePatch) -> Self {
		mocked(map: patch.map!, createdBy: patch.createdBy!) <- {
			$0.apply(patch)
		}
	}
	
	mutating func apply(_ patch: APIIssuePatch) {
		patch.isMarked >>? isMarked
		patch.wasAddedWithClient >>? wasAddedWithClient
		patch.description >>? description
		
		patch.craftsman >>? craftsman
		patch.map >>? map
		
		patch.positionX >>? positionX
		patch.positionY >>? positionY
		patch.positionZoomScale >>? positionZoomScale
		
		patch.createdAt >>? createdAt
		patch.createdBy >>? createdBy
		patch.resolvedAt >>? resolvedAt
		patch.resolvedBy >>? resolvedBy
		patch.closedAt >>? closedAt
		patch.closedBy >>? closedBy
	}
}

infix operator >>? : AssignmentPrecedence

/// overwrites RHS if LHS is some
private func >>? <T>(new: T?, existing: inout T) {
	if let new {
		existing = new
	}
}
