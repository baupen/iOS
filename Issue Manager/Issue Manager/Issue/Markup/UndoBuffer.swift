// Created by Julian Dunskus

import Foundation

final class UndoBuffer<Content> {
	let size: Int
	
	private var buffer: [Content] = []
	private var position = -1
	
	var canUndo: Bool {
		return position >= 0
	}
	
	var canRedo: Bool {
		return position + 1 < buffer.count
	}
	
	init(size: Int) {
		self.size = size
	}
	
	func push(_ content: Content) {
		if buffer.count < size {
			buffer.append(content)
			position += 1
		} else {
			buffer.removeFirst()
			buffer.append(content)
		}
	}
	
	func undo() -> Content {
		precondition(canUndo)
		defer { position -= 1 }
		return buffer[position]
	}
	
	func redo() -> Content {
		precondition(canRedo)
		defer { position += 1 }
		return buffer[position]
	}
}
