// Created by Julian Dunskus

import UIKit
import AVFoundation
import CGeometry
import HandyOperators

final class CameraContainerView: UIView {
	@IBOutlet private var cameraView: CameraView!
}

final class CameraView: UIView {
	var captureSession: AVCaptureSession?
	var photoOutput: AVCapturePhotoOutput?
	var previewLayer: AVCaptureVideoPreviewLayer?
	
	lazy var activityIndicator = UIActivityIndicatorView() <- {
		$0.autoresizingMask = .flexibleMargins
		$0.center = CGPoint(bounds.size / 2)
		$0.hidesWhenStopped = true
	}
	
	weak var delegate: CameraViewDelegate?
	
	private var isProcessing = false {
		didSet {
			if isProcessing {
				activityIndicator.startAnimating()
			} else {
				activityIndicator.stopAnimating()
			}
			previewLayer?.connection?.isEnabled = !isProcessing // pause
			previewLayer?.opacity = isProcessing ? 0.5 : 1
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
		addGestureRecognizer(tapRecognizer)
		
		addSubview(activityIndicator)
		
		configure()
	}
	
	deinit {
		captureSession?.stopRunning()
	}
	
	func configure() {
		guard captureSession?.isRunning != true else { return } // already configured
		
		DispatchQueue.global().async {
			if self.captureSession == nil {
				self.tryToConfigureSession()
			}
			
			self.captureSession?.startRunning()
		}
	}
	
	private func tryToConfigureSession() {
		do {
			captureSession = try AVCaptureSession() <- { session in
				let device = try AVCaptureDevice.default(for: .video) ??? CameraViewError.noCameraAvailable
				let input = try AVCaptureDeviceInput(device: device)
				session.addInput(input)
				
				self.photoOutput = AVCapturePhotoOutput() <- {
					session.sessionPreset = .photo
					session.addOutput($0)
				}
				
				self.previewLayer = AVCaptureVideoPreviewLayer(session: session) <- { preview in
					preview.videoGravity = .resizeAspectFill
					
					DispatchQueue.main.async { [preview] in
						self.layer.addSublayer(preview)
						self.updateOrientation()
						self.isHidden = false
					}
				}
			}
		} catch {
			print("Could not set up camera!")
			dump(error)
			
			DispatchQueue.main.async {
				self.isHidden = true
				self.delegate?.cameraFailed(with: error)
			}
		}
	}
	
	func takePhoto() {
		guard let photoOutput = photoOutput else {
			Haptics.notify.notificationOccurred(.error)
			delegate?.pictureFailed(with: CameraViewError.cameraNotConfigured)
			return
		}
		
		Haptics.lightImpact.impactOccurred()
		isProcessing = true
		
		let settings = AVCapturePhotoSettings() // jpeg
		#if !targetEnvironment(simulator)
		// work around this symbol being missing in xcode 12
		settings.flashMode = photoOutput.supportedFlashModes.contains(.auto) ? .auto : .off
		#endif
		photoOutput.capturePhoto(with: settings, delegate: self)
	}
	
	func prepareImagePicker(for source: UIImagePickerController.SourceType) -> UIImagePickerController? {
		guard UIImagePickerController.isSourceTypeAvailable(source) else { return nil }
		return UIImagePickerController() <- {
			$0.delegate = self
			$0.sourceType = source
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		previewLayer?.frame = layer.bounds
		
		updateOrientation()
	}
	
	@objc func updateOrientation() {
		guard let orientation = window?.windowScene?.interfaceOrientation else { return }
		let videoOrientation = AVCaptureVideoOrientation(representing: orientation)
		previewLayer?.connection!.videoOrientation = videoOrientation
		photoOutput?.connection(with: .video)!.videoOrientation = videoOrientation
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
			Haptics.notify.notificationOccurred(.error)
			delegate?.pictureFailed(with: error)
		} else {
			Haptics.notify.notificationOccurred(.success)
			let image = UIImage(data: photo.fileDataRepresentation()!)!
			delegate?.pictureTaken(image.standardized(shouldCrop: true))
		}
		
		DispatchQueue.main.async { // otherwise it's somehow still visible but unpaused
			self.isProcessing = false
		}
	}
}

extension CameraView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.presentingViewController!.dismiss(animated: true)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
		let image = info[.originalImage] as! UIImage
		delegate?.pictureSelected(image.standardized())
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
	/// Happens e.g. on the simulator, where there is no camera device available.
	case noCameraAvailable
	
	/// Is thrown when you try to take a picture while the camera isn't set up.
	case cameraNotConfigured
}

private extension UIImage {
	/// Applies image orientation.
	/// - parameter shouldCrop: if set, also crops to 4:3 in the process
	func standardized(shouldCrop: Bool = false) -> UIImage {
		let fullRect = CGRect(origin: .zero, size: size)
		let newRect = shouldCrop
			? AVMakeRect(
				aspectRatio: CGSize(width: 4, height: 3),
				insideRect: CGRect(origin: .zero, size: size)
			)
			: fullRect
		UIGraphicsBeginImageContextWithOptions(newRect.size, true, scale)
		defer { UIGraphicsEndImageContext() }
		draw(in: CGRect(origin: -newRect.origin, size: size))
		return UIGraphicsGetImageFromCurrentImageContext()!
	}
}

private extension AVCaptureVideoOrientation {
	init(representing orientation: UIInterfaceOrientation) {
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
			fallthrough
		@unknown default:
			print("unknown interface orientation!")
			self = .portrait
		}
	}
}
