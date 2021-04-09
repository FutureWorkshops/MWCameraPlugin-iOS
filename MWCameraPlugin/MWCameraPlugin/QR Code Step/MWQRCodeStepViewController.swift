//
//  MWQRCodeStepViewController.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 2/12/20.
//

import UIKit
import Foundation
import AVFoundation
import MobileWorkflowCore

public class MWQRCodeStepViewController: ORKStepViewController {
    
    //MARK: Private properties
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var qrStep: QrStep {
        guard let qrCodeStep = self.step as? QrStep else { preconditionFailure("Unexpected step type. Expecting \(String(describing: QrStep.self)), got \(String(describing: type(of: self.step)))") }
        return qrCodeStep
    }
    
    private var onCodeFound: ((String) -> Void)?
    
    //MARK: Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupVideoCapture()
                } else {
                    let alertController = UIAlertController(title: L10n.Camera.errorTitle, message: L10n.Camera.errorMessage, preferredStyle: .alert)
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.captureSession.isRunning {
            self.captureSession.startRunning()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [weak self] context in
            self?.updateOrientation()
        } completion: { context in }
    }
    
    //MARK: Private methods
    
    private func updateOrientation() {
        guard let interfaceOrientation = self.view.window?.windowScene?.interfaceOrientation else { return }
        
        let videoOrientation: AVCaptureVideoOrientation
        switch interfaceOrientation {
        case .landscapeRight: videoOrientation = .landscapeRight
        case .landscapeLeft: videoOrientation = .landscapeLeft
        case .portrait: videoOrientation = .portrait
        case .portraitUpsideDown: videoOrientation = .portraitUpsideDown
        case .unknown: videoOrientation = .portrait
        }
        self.previewLayer?.connection?.videoOrientation = videoOrientation
    }
    
    private func setupVideoCapture() {
        do {
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { throw NSError(domain: "MWCameraPlugin.qrCode", code: 0, userInfo: [NSLocalizedDescriptionKey:"This device doesn't support recording video."]) }
            
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            let metadataOutput = AVCaptureMetadataOutput()
            
            if self.captureSession.canAddInput(videoInput), self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addInput(videoInput)
                self.captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                throw NSError(domain: "MWCameraPlugin.qrCode", code: 1, userInfo: [NSLocalizedDescriptionKey:"This device can't scan for QR codes."])
            }
            
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer!.frame = self.view.layer.bounds
            self.previewLayer!.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(self.previewLayer!)
            self.updateOrientation()
            
            self.setupInfoView()
            
            let widthCameraView = self.view.bounds.width
            let heightCameraView = self.view.bounds.height
            self.view.mask(withRect: CGRect(x: 20*4,
                                            y: (heightCameraView / 2) - (widthCameraView / 2),
                                            width: widthCameraView - 40*4,
                                            height: widthCameraView - 40*4))
            
            self.captureSession.startRunning()
        } catch {
            
        }
    }
    
    private func setupInfoView() {
        var container: InformationView!
        
        if let step = self.qrStep as? MWCameraQRCodeStep {
            container = InformationView(description: L10n.Camera.qrLabel)
            
            self.onCodeFound = { [weak self] code in
                let result = MWQRCodeResult(identifier: step.identifier, qrCode: code)
                self?.addResult(result)
                self?.goForward()
            }
        } else {
            container = InformationView(title: "Scan QR Code", description: "Please scan the app's QR code to start your workflow")
            
            self.onCodeFound = { code in
                guard let url = URL(string: code) else {
                    return
                }
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        self.view.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            container.trailingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            container.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            container.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor)
        ])
    }
    
    private func found(code: String) {
        self.onCodeFound?(code)
    }
}

//MARK: AVCaptureMetadataOutputObjectsDelegate
extension MWQRCodeStepViewController: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let code = readableObject.stringValue,
           !code.isEmpty {
            self.found(code: code)
        } else {
            self.captureSession.startRunning()
        }
    }
}

private extension UIView {
    func mask(withRect rect: CGRect) {
        let path = UIBezierPath(rect: rect)
        
        let dashLength: CGFloat = 20.0
        let cornerPath = UIBezierPath()
        
        // top left
        cornerPath.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + dashLength))
        cornerPath.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        cornerPath.addLine(to: CGPoint(x: rect.origin.x + dashLength, y: rect.origin.y))
        
        // top right
        cornerPath.move(to: CGPoint(x: rect.origin.x + rect.width - dashLength, y: rect.origin.y))
        cornerPath.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y))
        cornerPath.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + dashLength))
        
        // bottom right
        cornerPath.move(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height - dashLength))
        cornerPath.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height))
        cornerPath.addLine(to: CGPoint(x: rect.origin.x + rect.width - dashLength, y: rect.origin.y + rect.height))
        
        // bottom left
        cornerPath.move(to: CGPoint(x: rect.origin.x + dashLength, y: rect.origin.y + rect.height))
        cornerPath.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
        cornerPath.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height - dashLength))
        

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = cornerPath.cgPath
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 4.0
        shapeLayer.fillColor = UIColor.clear.cgColor

        self.layer.addSublayer(shapeLayer)
    }
}
