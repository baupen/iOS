// Created by Julian Dunskus

import Foundation

struct JSendSuccess<Contents: Response>: Decodable {
	var data: Contents
}

struct JSendFailure: Decodable {
	var error: APIError
	var message: String
}

struct JSendError: Decodable {
	var message: String
}

enum APIError: Int, Error, Decodable {
	/// something in the request was malformed, e.g. missing value in json or missing image in multipart
	case invalidRequest = 1
	/// the authentication token is invalid, e.g. because it has expired
	case invalidToken = 2
	/// the client is outdated, thus the server won't risk communicating with it
	case outdatedClient = 3
	
	case unknownUsername = 100
	case wrongPassword = 101
	
	case issueAlreadyExists = 200
	case issueNotFound = 201
	/// the server ignored the issue change attempt because the client's data is outdated
	case outdatedData = 202
	/// whatever the client is trying to do is impossible, e.g. reviewing a closed issue
	case invalidAction = 203
	/// an unknown error occurred on the server
	case unknownError = 300
}
