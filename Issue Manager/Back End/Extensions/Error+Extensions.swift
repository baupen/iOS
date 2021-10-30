// Created by Julian Dunskus

import Foundation
import HandyOperators

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
	
	func dumpedDescription() -> String {
		"" <- { dump(self, to: &$0) }
	}
}
