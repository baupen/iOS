// Created by Julian Dunskus

import Foundation

/// - Note: The double optionals represent setting a value to nil (`.some(nil)`) vs not affecting it (`.none`)
struct IssuePatch: Codable {
	var isMarked: Bool?
	var wasAddedWithClient: Bool?
	var description: String??
	
	var craftsman: Craftsman.ID??
	var map: Map.ID??
	var constructionSite: ConstructionSite.ID??
	
	var positionX: Double??
	var positionY: Double??
	var positionZoomScale: Double??
	
	var createdAt: Date?
	var createdBy: ConstructionManager.ID?
	var resolvedAt: Date??
	var resolvedBy: Craftsman.ID??
	var closedAt: Date??
	var closedBy: ConstructionManager.ID??
}
