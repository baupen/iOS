import Foundation
import AVFoundation
import HandyOperators

// can't access non-Sendable values in deinit as of Xcode 15.1; this wraps AVCaptureSession in a sendable way
final actor CaptureSession {
	let session: AVCaptureSession
	
	init() throws {
		session = try AVCaptureSession() <- { session in
			let device = try AVCaptureDevice.default(for: .video) ??? CameraViewError.noCameraAvailable
			let input = try AVCaptureDeviceInput(device: device)
			session.addInput(input)
			session.sessionPreset = .photo
		}
	}
	
	func start() {
		session.startRunning()
	}
	
	func stop() {
		session.stopRunning()
	}
	
	func makePhotoOutput() -> UncheckedSendable<AVCapturePhotoOutput> {
		.init(.init() <- { session.addOutput($0) })
	}
	
	func makeMetadataOutput() -> UncheckedSendable<AVCaptureMetadataOutput> {
		.init(.init() <- { session.addOutput($0) })
	}
	
	func makePreview() -> UncheckedSendable<AVCaptureVideoPreviewLayer> {
		.init(.init(session: session))
	}
}
