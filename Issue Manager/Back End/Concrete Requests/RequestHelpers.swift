// Created by Julian Dunskus

import Foundation
import Promise

extension Client {
	func getUser() -> Future<User> {
		Future { try localUser?.user ??? RequestError.notAuthenticated }
	}
}

extension Future {
	func ignoringResult() -> Future<Void> {
		self.map { _ in }
	}
}

func logOutcome<T>(of future: Future<T>, as method: String) {
	future.then { _ in
		print("\(method) completed successfully")
	}
	
	future.catch { error in
		error.printDetails(context: "\(method) encountered error:")
	}
}
