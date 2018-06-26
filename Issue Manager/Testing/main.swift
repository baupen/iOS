// Created by Julian Dunskus

import Foundation

/*
let data = """
{
	"data": [],
	"status": "success"
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
do {
	let response = try decoder.decode(JSendSuccess<EmptyCollection<Void>>.self, from: data)
	dump(response)
} catch {
	dump(error)
}

exit(0)
*/

let group = DispatchGroup()

let client = Client.shared

group.enter()
client.read().then {
	var issue = Issue(in: client.storage.maps.values.first!, wasAddedWithClient: false)
	issue.description = "test69"
	issue.imageFilename = "ahri_4.jpg"
	client.storage.issues[issue.id] = issue
	client.issueCreated(issue)
	DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
		client.storage.issues[issue.id] = nil
		client.issueRemoved(issue)
	}
}

group.wait()
