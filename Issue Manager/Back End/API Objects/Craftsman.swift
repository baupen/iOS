// Created by Julian Dunskus

import Foundation

struct Craftsman: APIObject, Equatable {
	var meta: ObjectMeta
	var name: String
	var trade: String
}
