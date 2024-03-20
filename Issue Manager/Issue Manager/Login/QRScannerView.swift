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
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// only now can we handle errors with alerts
		scannerView.configure()
	}
}

final class QRScannerView: UIView {
	var captureSession: CaptureSession?
	var metadataOutput: AVCaptureMetadataOutput?
	var previewLayer: AVCaptureVideoPreviewLayer?
	
	lazy var activityIndicator = UIActivityIndicatorView() <- {
		$0.autoresizingMask = .flexibleMargins
		$0.center = CGPoint(bounds.size / 2)
		$0.hidesWhenStopped = true
	}
	
	weak var delegate: QRScannerViewDelegate?
	
	private var isProcessing = false {
		didSet {
			if isProcessing {
				activityIndicator.startAnimating()
				Task {
					await captureSession?.stop()
				}
			} else {
				activityIndicator.stopAnimating()
				Task {
					await captureSession?.start()
				}
			}
			
			previewLayer?.connection?.isEnabled = !isProcessing // pause
			previewLayer?.opacity = isProcessing ? 0.5 : 1
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		addSubview(activityIndicator)
	}
	
	deinit {
		Task { [captureSession] in
			await captureSession?.stop()
		}
	}
	
	func configure() {
		do {
			let session = try CaptureSession()
			captureSession = session
			
			Task.detached(priority: .userInitiated) {
				await session.start()
				
				await self.connect(to: session)
			}
		} catch {
			print("Could not set up camera!")
			dump(error)
			
			delegate?.cameraFailed(with: error)
		}
	}
	
	private func connect(to session: CaptureSession) async {
		self.metadataOutput = await session.makeMetadataOutput().value <- {
			$0.setMetadataObjectsDelegate(self, queue: .main)
			$0.metadataObjectTypes = [.qr]
		}
		
		self.previewLayer = await session.makePreview().value <- { preview in
			preview.videoGravity = .resizeAspectFill
			
			self.layer.addSublayer(preview)
			self.updateOrientation()
			self.isHidden = false
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
	nonisolated func metadataOutput(
		_ output: AVCaptureMetadataOutput,
		didOutput metadataObjects: [AVMetadataObject],
		from connection: AVCaptureConnection
	) {
		let qrs = metadataObjects
			.compactMap { $0 as? AVMetadataMachineReadableCodeObject }
			.compactMap { $0.stringValue }
		guard !qrs.isEmpty else { return }
		Task { @MainActor in
			guard !isProcessing else { return }
			if let delegate {
				isProcessing = delegate.qrsFound(withContents: qrs)
			}
		}
	}
}

@MainActor
protocol QRScannerViewDelegate: AnyObject {
	func cameraFailed(with error: Error)
	/// - returns: whether to block further input from the scanner
	func qrsFound(withContents contents: [String]) -> Bool
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
