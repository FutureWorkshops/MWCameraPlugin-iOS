//
//  MWQRCodeStepViewController.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 2/12/20.
//

import UIKit
import Foundation
import AVFoundation

class MWQRCodeStepViewController: UIViewController {
    
    //MARK: Private properties
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.setupVideoCapture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.captureSession.isRunning {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    //MARK: Private methods
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
            self.previewLayer!.frame = view.layer.bounds
            self.previewLayer!.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(previewLayer!)
            
            self.captureSession.startRunning()
        } catch {
            
        }
    }
    
    private func found(code: String) {
        print(code)
    }

}

//MARK: AVCaptureMetadataOutputObjectsDelegate
extension MWQRCodeStepViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            self.found(code: stringValue)
        } else {
            self.captureSession.startRunning()
        }
    }
}
