// Created by Julian Dunskus

import UIKit
import AVFoundation
import CGeometry
import HandyOperators

final class QRScannerViewController: UIViewController {
	@IBOutlet private(set) var scannerView: QRScannerView!
	
	weak var delegate: QRScannerViewDelegate? {
		didSet { scannerView?.delegate = delegate }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		scannerView.delegate = delegate
	}
}

final class QRScannerView: UIView {
	var captureSession: AVCaptureSession?
	var metadataOutput: AVCaptureMetadataOutput?
	var previewLayer: AVCaptureVideoPreviewLayer?
	
	lazy var activityIndicator = UIActivityIndicatorView() <- {
		$0.autoresizingMask = .flexibleMargins
		$0.center = CGPoint(bounds.size / 2)
		$0.hidesWhenStopped = true
	}
	
	weak var delegate: QRScannerViewDelegate?
	
	var isProcessing = false {
		didSet {
			if isProcessing {
				activityIndicator.startAnimating()
				captureSession?.stopRunning()
			} else {
				activityIndicator.stopAnimating()
				captureSession?.startRunning()
			}
			
			previewLayer?.connection?.isEnabled = !isProcessing // pause
			previewLayer?.opacity = isProcessing ? 0.5 : 1
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
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
				session.addInput(try AVCaptureDeviceInput(device: device))
				
				self.metadataOutput = AVCaptureMetadataOutput() <- {
					session.addOutput($0)
					$0.setMetadataObjectsDelegate(self, queue: .main)
					$0.metadataObjectTypes = [.qr]
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
				self.delegate?.cameraFailed(with: error)
			}
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
	}
}

extension QRScannerView: AVCaptureMetadataOutputObjectsDelegate {
	func metadataOutput(
		_ output: AVCaptureMetadataOutput,
		didOutput metadataObjects: [AVMetadataObject],
		from connection: AVCaptureConnection
	) {
		guard !isProcessing else { return }
		let qrs = metadataObjects
			.compactMap { $0 as? AVMetadataMachineReadableCodeObject }
			.compactMap { $0.stringValue }
		guard !qrs.isEmpty else { return }
		delegate?.qrsFound(by: self, with: qrs)
	}
}

protocol QRScannerViewDelegate: AnyObject {
	func cameraFailed(with error: Error)
	func qrsFound(by scanner: QRScannerView, with contents: [String])
}

enum QRScannerViewError: Error {
	/// Happens e.g. on the simulator, where there is no camera device available.
	case noCameraAvailable
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
