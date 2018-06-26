// Created by Julian Dunskus

import CoreGraphics

protocol Vector2 {
	var x: CGFloat { get set }
	var y: CGFloat { get set }
	
	init(x: CGFloat, y: CGFloat)
	
	var asVector: CGVector { get }
	var asPoint: CGPoint { get }
	var asSize: CGSize { get }
	
	var length: CGFloat { get }
	var angle: CGFloat { get }
	
	func clamped(to length: CGFloat) -> Self
	
	func map(_ transform: (CGFloat) throws -> CGFloat) rethrows -> Self
	
	static var zero: Self { get }
	static var one: Self { get }
	
	static func += <V: Vector2>(lhs: inout Self, rhs: V)
	static func -= <V: Vector2>(lhs: inout Self, rhs: V)
	static func *= (vec: inout Self, scale: CGFloat)
	static func /= (vec: inout Self, scale: CGFloat)
	
	static prefix func - (vec: Self) -> Self
	
	static func + <V: Vector2>(lhs: Self, rhs: V) -> Self
	static func - <V: Vector2>(lhs: Self, rhs: V) -> Self
	static func * (vec: Self, scale: CGFloat) -> Self
	static func * (scale: CGFloat, vec: Self) -> Self
	static func * <V: Vector2>(lhs: Self, rhs: V) -> Self
	static func / (vec: Self, scale: CGFloat) -> Self
	static func / <V: Vector2>(lhs: Self, rhs: V) -> Self
}

extension Vector2 {
	static var zero: Self {
		return Self(x: 0, y: 0)
	}
	
	static var one: Self {
		return Self(x: 1, y: 1)
	}
	
	var asVector: CGVector {
		return CGVector(dx: x, dy: y)
	}
	
	var asPoint: CGPoint {
		return CGPoint(x: x, y: y)
	}
	
	var asSize: CGSize {
		return CGSize(width: x, height: y)
	}
	
	var length: CGFloat {
		return hypot(x, y)
	}
	
	var angle: CGFloat {
		return atan2(y, x)
	}
	
	func clamped(to length: CGFloat) -> Self {
		let len = self.length
		
		if len > length {
			return self * (length / len)
		}
		return self
	}
	
	func map(_ transform: (CGFloat) throws -> CGFloat) rethrows -> Self {
		return Self(x: try transform(x),
					y: try transform(y))
	}
	
	static func += <V: Vector2>(lhs: inout Self, rhs: V) {
		lhs.x += rhs.x
		lhs.y += rhs.y
	}
	
	static func -= <V: Vector2>(lhs: inout Self, rhs: V) {
		lhs.x -= rhs.x
		lhs.y -= rhs.y
	}
	
	static func *= (vec: inout Self, scale: CGFloat) {
		vec.x *= scale
		vec.y *= scale
	}
	
	static func /= (vec: inout Self, scale: CGFloat) {
		vec.x /= scale
		vec.y /= scale
	}
	
	static func + <V: Vector2>(lhs: Self, rhs: V) -> Self {
		return Self(x: lhs.x + rhs.x,
					y: lhs.y + rhs.y)
	}
	
	static func - <V: Vector2>(lhs: Self, rhs: V) -> Self {
		return Self(x: lhs.x - rhs.x,
					y: lhs.y - rhs.y)
	}
	
	static func * (vec: Self, scale: CGFloat) -> Self {
		return Self(x: vec.x * scale,
					y: vec.y * scale)
	}
	
	static func * (scale: CGFloat, vec: Self) -> Self {
		return Self(x: vec.x * scale,
					y: vec.y * scale)
	}
	
	static func * <V: Vector2>(lhs: Self, rhs: V) -> Self {
		return Self(x: lhs.x * rhs.x,
					y: lhs.y * rhs.y)
	}
	
	static func / (vec: Self, scale: CGFloat) -> Self {
		return Self(x: vec.x / scale,
					y: vec.y / scale)
	}
	
	static prefix func - (vec: Self) -> Self {
		return Self(x: -vec.x,
					y: -vec.y)
	}
	
	static func / <V: Vector2>(lhs: Self, rhs: V) -> Self {
		return Self(x: lhs.x / rhs.x,
					y: lhs.y / rhs.y)
	}
}

extension CGPoint: Vector2 {}

extension CGVector: Vector2 {
	var x: CGFloat {
		get { return dx }
		set { dx = newValue }
	}
	
	var y: CGFloat {
		get { return dy }
		set { dy = newValue }
	}
	
	init(x: CGFloat, y: CGFloat) {
		self.init(dx: x, dy: y)
	}
}

extension CGSize: Vector2 {
	var x: CGFloat {
		get { return width }
		set { width = newValue }
	}
	
	var y: CGFloat {
		get { return height }
		set { height = newValue }
	}
	
	init(x: CGFloat, y: CGFloat) {
		self.init(width: x, height: y)
	}
}

extension CGRect {
	static func * <V: Vector2>(rect: CGRect, scale: V) -> CGRect {
		return CGRect(origin: rect.origin * scale, size: rect.size * scale)
	}
	
	static func * <V: Vector2>(scale: V, rect: CGRect) -> CGRect {
		return CGRect(origin: rect.origin * scale, size: rect.size * scale)
	}
	
	static func / <V: Vector2>(rect: CGRect, scale: V) -> CGRect {
		return CGRect(origin: rect.origin / scale, size: rect.size / scale)
	}
	
	static func / <V: Vector2>(scale: V, rect: CGRect) -> CGRect {
		return CGRect(origin: rect.origin / scale, size: rect.size / scale)
	}
}
