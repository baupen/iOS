// Created by Julian Dunskus

import UIKit

fileprivate func localizedString(_ key: String) -> String {
	return NSLocalizedString(key, comment: "")
}

extension UITextField {
	@IBInspectable
	var localizedPlaceholder: String {
		get { return "" }
		set(key) {
			placeholder = localizedString(key)
		}
	}
}

extension UIBarButtonItem {
	@IBInspectable
	var localizedTitle: String {
		get { return "" }
		set(key) {
			title = localizedString(key)
		}
	}
}
