// Created by Julian Dunskus

import Foundation
import HandyOperators

extension Error {
	var localizedFailureReason: String {
		(self as NSError).localizedFailureReason ?? localizedDescription
	}
	
	func printDetails(context: String) {
		var output = ""
		print("———————————————————————— ERROR ————————————————————————", to: &output)
		print(context, localizedFailureReason, to: &output)
		print(self, to: &output)
		dump(self, to: &output)
		print(to: &output)
		// make sure we're printing all at once
		print(output)
	}
	
	func dumpedDescription() -> String {
		"" <- { dump(self, to: &$0) }
	}
}
