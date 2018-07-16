// Created by Julian Dunskus

import UIKit
import AVFoundation

final class CameraContainerView: UIView {
	@IBOutlet var cameraView: CameraView!
}

final class CameraView: UIView {
	var captureSession: AVCaptureSession?
	var captureDevice: AVCaptureDevice?
	var captureInput: AVCaptureDeviceInput?
	var photoOutput: AVCapturePhotoOutput?
	var previewLayer: AVCaptureVideoPreviewLayer?
	
	weak var delegate: CameraViewDelegate?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateOrientation), name: .UIApplicationDidChangeStatusBarOrientation, object: nil)
		
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
		addGestureRecognizer(tapRecognizer)
		
		configure()
	}
	
	deinit {
		captureSession?.stopRunning()
	}
	
	func configure() {
		guard captureSession?.isRunning != true else { return } // already configured
		
		DispatchQueue.global().async {
			if self.captureSession == nil {
				let session = AVCaptureSession()
				self.captureSession = session
				
				let device = AVCaptureDevice.default(for: .video)!
				self.captureDevice = device
				
				do {
					let input = try AVCaptureDeviceInput(device: device)
					self.captureInput = input
					session.addInput(input)
				} catch {
					print("could not set up camera!")
					dump(error)
					DispatchQueue.main.async {
						self.isHidden = true
						self.delegate?.cameraFailed(with: error)
					}
					
					return
				}
				
				let photoOutput = AVCapturePhotoOutput()
				self.photoOutput = photoOutput
				session.sessionPreset = .photo
				session.addOutput(photoOutput)
				
				let previewLayer = AVCaptureVideoPreviewLayer(session: session)
				self.previewLayer = previewLayer
				previewLayer.videoGravity = .resizeAspectFill
				
				DispatchQueue.main.async {
					self.layer.addSublayer(previewLayer)
					self.updateOrientation()
					self.isHidden = false
				}
			}
			
			self.captureSession!.startRunning()
		}
	}
	
	func takePhoto() {
		guard let photoOutput = photoOutput else {
			delegate?.pictureFailed(with: CameraViewError.cameraNotConfigured)
			return
		}
		
		let settings = AVCapturePhotoSettings() // jpeg
		photoOutput.capturePhoto(with: settings, delegate: self)
	}
	
	func prepareImagePicker(for source: UIImagePickerControllerSourceType) -> UIImagePickerController? {
		guard UIImagePickerController.isSourceTypeAvailable(source) else { return nil }
		let picker = UIImagePickerController()
		picker.delegate = self
		picker.sourceType = source
		return picker
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		previewLayer?.frame = layer.bounds
	}
	
	@objc func updateOrientation() {
		let orientation = UIApplication.shared.statusBarOrientation // kinda dirty
		previewLayer?.connection!.videoOrientation = .init(representing: orientation)
		photoOutput?.connection(with: .video)!.videoOrientation = .init(representing: orientation)
	}
	
	@objc func viewTapped(_ tapRecognizer: UITapGestureRecognizer) {
		if tapRecognizer.state == .recognized {
			takePhoto()
		}
	}
}

extension CameraView: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		if let error = error {
			delegate?.pictureFailed(with: error)
		} else {
			let image = UIImage(data: photo.fileDataRepresentation()!)!
			delegate?.pictureTaken(image.cropped())
		}
	}
}

extension CameraView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.presentingViewController!.dismiss(animated: true)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
		let image = info[UIImagePickerControllerOriginalImage] as! UIImage
		delegate?.pictureSelected(image.cropped())
		picker.presentingViewController!.dismiss(animated: true)
	}
}

protocol CameraViewDelegate: AnyObject {
	func cameraFailed(with error: Error)
	func pictureTaken(_ image: UIImage)
	func pictureFailed(with error: Error)
	func pictureSelected(_ image: UIImage)
}

enum CameraViewError: Error {
	case cameraNotConfigured
}

extension UIImage {
	/// crops to 4:3, applying orientation in the process
	func cropped() -> UIImage {
		let newRect = AVMakeRect(
			aspectRatio: CGSize(width: 4, height: 3),
			insideRect: CGRect(origin: .zero, size: size)
		)
		UIGraphicsBeginImageContextWithOptions(newRect.size, true, scale)
		defer { UIGraphicsEndImageContext() }
		draw(in: CGRect(origin: -newRect.origin, size: size))
		return UIGraphicsGetImageFromCurrentImageContext()!
	}
}

extension AVCaptureVideoOrientation {
	fileprivate init(representing orientation: UIInterfaceOrientation) {
		// no, this is not a nop
		switch orientation {
		case .portrait:
			self = .portrait
		case .portraitUpsideDown:
			self = .portraitUpsideDown
		case .landscapeRight:
			self = .landscapeRight
		case .landscapeLeft:
			self = .landscapeLeft
		case .unknown:
			print("unknown interface orientation!")
			self = .portrait
		}
	}
}
