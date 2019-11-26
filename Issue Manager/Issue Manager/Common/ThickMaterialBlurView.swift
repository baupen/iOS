import UIKit

final class ThickMaterialBlurView: UIVisualEffectView {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		if #available(iOS 13.0, *) {
			effect = UIBlurEffect(style: .systemThickMaterial)
		}
	}
}
