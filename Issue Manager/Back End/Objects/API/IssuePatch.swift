// Created by Julian Dunskus

import Foundation

/// - Note: The double optionals represent setting a value to nil (`.some(nil)`) vs not affecting it (`.none`)
struct IssuePatch: Equatable, Codable {
	var isMarked: Bool?
	var wasAddedWithClient: Bool?
	var description: String??
	
	var craftsman: APICraftsman.ID??
	var map: Map.ID??
	var constructionSite: APIConstructionSite.ID??
	
	var positionX: Double??
	var positionY: Double??
	var positionZoomScale: Double??
	
	var createdAt: Date?
	var createdBy: APIConstructionManager.ID?
	var resolvedAt: Date??
	var resolvedBy: APICraftsman.ID??
	var closedAt: Date??
	var closedBy: APIConstructionManager.ID??
}
