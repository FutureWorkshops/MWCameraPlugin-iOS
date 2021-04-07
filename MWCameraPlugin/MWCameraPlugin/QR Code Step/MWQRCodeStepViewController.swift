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
    private var qrCodeStep: MWCameraQRCodeStep {
        guard let qrCodeStep = self.step as? MWCameraQRCodeStep else { preconditionFailure("Unexpected step type. Expecting \(String(describing: MWCameraQRCodeStep.self)), got \(String(describing: type(of: self.step)))") }
        return qrCodeStep
    }
    
    //MARK: Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupVideoCapture()
                } else {
                    let alertController = UIAlertController(title: "Error", message: "Camera permission is denied. Please, grant access to the camera in the Settings app.", preferredStyle: .alert)
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
        
        coordinator.animate { context in
            self.updateOrientation()
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
            
            let labelContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            labelContainer.translatesAutoresizingMaskIntoConstraints = false
            labelContainer.layer.cornerRadius = 4
            labelContainer.layer.masksToBounds = true
            
            let label = UILabel(frame: .zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Focus on a QR code"
            label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            label.numberOfLines = 0
            label.textAlignment = .center
            
            labelContainer.contentView.addSubview(label)
            self.view.addSubview(labelContainer)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor, constant: -8),
                label.topAnchor.constraint(equalTo: labelContainer.topAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor, constant: -8),
                
                labelContainer.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
                labelContainer.trailingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
                labelContainer.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
                labelContainer.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor)
            ])
            
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
    
    private func found(code: String) {
        let result = MWQRCodeResult(identifier: self.qrCodeStep.identifier, qrCode: code)
        self.addResult(result)
        self.goForward()
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
