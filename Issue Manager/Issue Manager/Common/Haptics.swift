import UIKit

final class Haptics {
	static let lightImpact = UIImpactFeedbackGenerator(style: .light)
	static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
	static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
	static let select = UISelectionFeedbackGenerator()
	static let notify = UINotificationFeedbackGenerator()
}
