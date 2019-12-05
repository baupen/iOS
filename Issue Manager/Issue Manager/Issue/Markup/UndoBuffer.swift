// Created by Julian Dunskus

import Foundation

final class UndoBuffer<Content> {
	let size: Int
	
	private var buffer: [Content] = []
	private var position = -1
	
	var canUndo: Bool {
		position > 0
	}
	
	var canRedo: Bool {
		position + 1 < buffer.count
	}
	
	init(size: Int) {
		self.size = size
	}
	
	func clear() {
		position = -1
		buffer = []
	}
	
	func push(_ content: Content) {
		guard size > 0 else { return } // always-empty buffer
		
		if buffer.count < size {
			if position + 1 < buffer.count {
				// clear redo states
				buffer.removeLast(buffer.count - (position + 1))
			}
			
			buffer.append(content)
			position += 1
		} else {
			// buffer full; cycle
			buffer.removeFirst()
			buffer.append(content)
		}
	}
	
	func undo() -> Content {
		precondition(canUndo)
		position -= 1
		return buffer[position]
	}
	
	func redo() -> Content {
		precondition(canRedo)
		position += 1
		return buffer[position]
	}
}
