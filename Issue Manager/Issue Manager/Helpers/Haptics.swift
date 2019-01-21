import UIKit

final class Haptics {
	static let impact = UIImpactFeedbackGenerator()
	static let select = UISelectionFeedbackGenerator()
	static let notify = UINotificationFeedbackGenerator()
	
	/// Generates haptic feedback if possible, fails silently otherwise
	static func generateFeedback(_ type: FeedbackType) {
		switch type {
		case .strong:
			Haptics.impact.impactOccurred()
		case .weak:
			Haptics.select.selectionChanged()
		case .strongDouble:
			Haptics.notify.notificationOccurred(.success)
		case .weakDouble:
			Haptics.notify.notificationOccurred(.warning)
		case .many:
			Haptics.notify.notificationOccurred(.error)
		}
	}
	
	enum FeedbackType {
		case strong
		case weak
		case strongDouble, weakDouble, many
	}
}
