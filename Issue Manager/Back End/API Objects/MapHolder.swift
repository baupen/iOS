// Created by Julian Dunskus

import Foundation

protocol MapHolder {
	var name: String { get }
	var filename: String? { get }
	
	func childMaps() -> [Map]
	func allIssues() -> [Issue]
}

extension Building: MapHolder {}
extension Map: MapHolder {}
