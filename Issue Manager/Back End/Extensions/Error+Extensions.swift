// Created by Julian Dunskus

import Foundation

extension Error {
	var localizedFailureReason: String {
		return (self as NSError).localizedFailureReason ?? localizedDescription
	}
}
