// Created by Julian Dunskus

import Foundation

protocol MapHolder: APIObject {
	var name: String { get }
	
	func childMaps() -> [Map]
	func allIssues() -> [Issue]
}

extension Building: MapHolder {}
extension Map: MapHolder {}
