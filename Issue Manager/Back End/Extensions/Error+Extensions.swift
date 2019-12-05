// Created by Julian Dunskus

import Foundation

extension Error {
	var localizedFailureReason: String {
		(self as NSError).localizedFailureReason ?? localizedDescription
	}
	
	func printDetails(context: String) {
		print("———————————————————————— ERROR ————————————————————————")
		print(context, localizedFailureReason)
		print(self)
		dump(self)
		print()
	}
}
