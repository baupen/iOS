// Created by Julian Dunskus

import Foundation
import Promise

extension Future {
	func logOutcome(as method: String) {
		self
			.then { _ in
				print("\(method) completed successfully")
			}
			.catch { error in
				error.printDetails(context: "\(method) encountered error:")
			}
	}
}
