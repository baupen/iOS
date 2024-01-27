// Created by Julian Dunskus

import Foundation

struct IssuePatch: Equatable, Codable, Sendable {
	// the defaults for these fields don't matter since they won't be encoded; using non-optionals just ensures they can't be set to nil
	
	@Tracked var isMarked = false
	@Tracked var wasAddedWithClient = false
	@Tracked var description: String?
	
	@Tracked var craftsmanID: Craftsman.ID?
	@Tracked var mapID: Map.ID?
	@Tracked var constructionSiteID: ConstructionSite.ID?
	
	@Tracked var position: Issue.Position?
	
	@Tracked var createdAt = Date()
	@Tracked var createdBy = ConstructionManager.ID()
	@Tracked var resolvedAt: Date?
	@Tracked var resolvedBy: Craftsman.ID?
	@Tracked var closedAt: Date?
	@Tracked var closedBy: ConstructionManager.ID?
	
	init() {}
	
	func makeModel() -> APIIssuePatch {
		APIIssuePatch(
			isMarked: $isMarked,
			wasAddedWithClient: $wasAddedWithClient,
			description: $description,
			craftsman: _craftsmanID.modelID,
			map: _mapID.modelID,
			constructionSite: _constructionSiteID.modelID,
			positionX: _position.x,
			positionY: _position.y,
			positionZoomScale: _position.zoomScale,
			createdAt: $createdAt,
			createdBy: _createdBy.modelID,
			resolvedAt: $resolvedAt,
			resolvedBy: _resolvedBy.modelID,
			closedAt: $closedAt,
			closedBy: _closedBy.modelID
		)
	}
	
	@propertyWrapper
	@dynamicMemberLookup
	struct Tracked<Value: Sendable>: Sendable {
		var wrappedValue: Value {
			didSet { wasChanged = true }
		}
		
		var projectedValue: Value? { wasChanged ? wrappedValue : nil }
		
		private(set) var wasChanged = false
		
		subscript<T>(dynamicMember path: KeyPath<Value, T>) -> T? {
			projectedValue.map { $0[keyPath: path] }
		}
		
		subscript<Wrapped, T>(dynamicMember path: KeyPath<Wrapped, T>) -> T??
		where Value == Optional<Wrapped> {
			projectedValue.map { $0?[keyPath: path] }
		}
	}
}

/// - Note: The double optionals represent setting a value to nil (`.some(nil)`) vs not affecting it (`.none`)
struct APIIssuePatch: Encodable {
	var isMarked: Bool?
	var wasAddedWithClient: Bool?
	var description: String??
	
	var craftsman: APICraftsman.ID??
	var map: APIMap.ID??
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

extension IssuePatch.Tracked: Equatable where Value: Equatable {}
extension IssuePatch.Tracked: Encodable where Value: Encodable {}
extension IssuePatch.Tracked: Decodable where Value: Decodable {}
