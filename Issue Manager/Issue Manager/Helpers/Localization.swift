// Created by Julian Dunskus

import UIKit

fileprivate func localizedString(_ key: String) -> String {
	return NSLocalizedString(key, comment: "")
}

extension UILabel {
	@IBInspectable
	var localizedText: String {
		get { return "" }
		set(key) {
			if key.hasSuffix(":") { // cheeky shorthand because i use this a lot
				text = "\(localizedString(String(key.dropLast()))):"
			} else {
				text = localizedString(key)
			}
		}
	}
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

extension UIButton {
	@IBInspectable
	var localizedTitle: String {
		get { return "" }
		set(key) {
			setTitle(localizedString(key), for: .normal)
		}
	}
}

extension UINavigationItem {
	@IBInspectable
	var localizedTitle: String {
		get { return "" }
		set(key) {
			title = localizedString(key)
		}
	}
}
