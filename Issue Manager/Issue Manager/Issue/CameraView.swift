// Created by Julian Dunskus

import UIKit
import AVFoundation

final class CameraView: UIView {
	var videoCaptureDevice: AVCaptureDevice!
	var captureSession: AVCaptureSession!
	var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		videoCaptureDevice = AVCaptureDevice.default(for: .video)
		do {
			let input = try AVCaptureDeviceInput(device: videoCaptureDevice)
			let session = AVCaptureSession()
			self.captureSession = session
			session.addInput(input)
			let previewLayer = AVCaptureVideoPreviewLayer(session: session)
			videoPreviewLayer = previewLayer
			layer.addSublayer(previewLayer)
			previewLayer.videoGravity = .resizeAspectFill
			session.startRunning()
		} catch {
			print("could not set up camera!", error.localizedDescription)
			dump(error)
		}
	}
	
	func takePhoto() -> Future<UIImage> {
		captureSession.beginConfiguration()
		let photoOutput = AVCapturePhotoOutput()
		captureSession.sessionPreset = .medium
		captureSession.addOutput(photoOutput)
		captureSession.commitConfiguration()
		
		let settings = AVCapturePhotoSettings() // jpeg
		settings.flashMode = .auto
		return Future { resolver in photoOutput.capturePhoto(with: settings, delegate: CaptureDelegate(using: resolver)) }
			.map { UIImage(cgImage: $0.cgImageRepresentation()!.takeRetainedValue()).applyingOrientation() }
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		videoPreviewLayer?.frame = layer.bounds
	}
	
	private class CaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
		var resolver: Resolver<AVCapturePhoto>
		
		init(using resolver: Resolver<AVCapturePhoto>) {
			self.resolver = resolver
		}
		
		func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
			if let error = error {
				resolver.reject(with: error)
			} else {
				resolver.fulfill(with: photo)
			}
		}
	}
}

extension UIImage {
	func applyingOrientation() -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		defer { UIGraphicsEndImageContext() }
		draw(in: CGRect(origin: .zero, size: size))
		return UIGraphicsGetImageFromCurrentImageContext()!
	}
}
