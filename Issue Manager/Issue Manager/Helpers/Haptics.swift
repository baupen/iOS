import UIKit

class Haptics {
	/// Generates haptic feedback if possible, fails silently otherwise
	static func generateFeedback(_ type: FeedbackType) {
		switch type {
		case .strong:
			Generators.impact.impactOccurred()
		case .weak:
			Generators.select.selectionChanged()
		case .strongDouble:
			Generators.notify.notificationOccurred(.success)
		case .weakDouble:
			Generators.notify.notificationOccurred(.warning)
		case .many:
			Generators.notify.notificationOccurred(.error)
		}
	}
	
	private class Generators {
		static let impact = UIImpactFeedbackGenerator()
		static let select = UISelectionFeedbackGenerator()
		static let notify = UINotificationFeedbackGenerator()
	}
	
	enum FeedbackType {
		case strong, weak, strongDouble, weakDouble, many
	}
}
