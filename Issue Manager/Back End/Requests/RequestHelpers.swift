// Created by Julian Dunskus

import Foundation
import Promise

extension Client {
	func getUser() -> Future<User> {
		return user.map(Future.fulfilled) ?? .rejected(with: RequestError.notAuthenticated)
	}
}

extension Future {
	func ignoringResult() -> Future<Void> {
		return self.map { _ in }
	}
}

func logOutcome<T>(of future: Future<T>, as method: String) {
	future.then { _ in
		print("\(method) completed successfully")
	}
	
	future.catch { error in
		print("\(method) encountered error:")
		print(error.localizedFailureReason)
		dump(error)
	}
}
