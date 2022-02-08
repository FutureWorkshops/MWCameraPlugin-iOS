//
//  MWImageCaptureView.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 07/12/2021.
//

import UIKit
import AVKit
import MobileWorkflowCore

protocol MWImageCaptureViewDelegate : AnyObject {
    func capturePressed(handler: ((Bool) -> Void)?)
    func retakePressed(handler: (() -> Void)?)
    func videoOrientationDidChange(videoOrientation: AVCaptureVideoOrientation)
}

final class MWImageCaptureView : UIView {
    
    weak var delegate: MWImageCaptureViewDelegate?
    
    private lazy var previewView = MWImageCaptureCameraPreviewView()

    private var variableConstraints : [NSLayoutConstraint] = []
    
    var templateImage : UIImage? {
        get{
            return self.previewView.templateImage
        }
        set {
            self.previewView.templateImage = newValue
            self.updateAppearance()
        }
    }
    
    var error: Error? {
        didSet{
            self.updateAppearance()
        }
    }
    
    private var capturePressesIgnored : Bool = false
    private var retakePressesIgnored : Bool = false
    private var showSkipButtonItem : Bool = false
    
    let imageCaptureStep : MWImageCaptureStep
    
    init(imageCaptureStep : MWImageCaptureStep, frame: CGRect) {
        
        self.imageCaptureStep = imageCaptureStep
        
        self.showSkipButtonItem = imageCaptureStep.isOptional ?? false
        
        super.init(frame: frame)
        
        self.addSubview(self.previewView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationDidChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.queue_sessionRunning), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionWasInterrupted(notification:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionInterruptionEnded(notification:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: nil)
        
        self.updateAppearance()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func capturePressed(){
        // If we are still waiting for the delegate to complete, ignore futher presses
        if self.capturePressesIgnored { return }

        // Ignore futher presses until the delegate completes
        self.capturePressesIgnored = true

        // Capture the image via the delegate
        self.delegate?.capturePressed(handler: { [weak self] _ in
            self?.capturePressesIgnored = false
        })
        
    }
    
    @IBAction func retakePressed(){
        
        // If we are still waiting for the delegate to complete, ignore futher presses
        if self.retakePressesIgnored { return }

        // Ignore futher presses until the delegate completes
        self.retakePressesIgnored = true

        // Tell the delegate to start capturing again
        self.delegate?.retakePressed(handler: { [weak self] in
            self?.retakePressesIgnored = false
        })
    
    }
    
    @IBAction func orientationDidChange(){
        DispatchQueue.main.async {
            guard let interfaceOrientation = self.window?.windowScene?.interfaceOrientation else {return}
            var orientation : AVCaptureVideoOrientation = .portrait
            switch interfaceOrientation {
            case .landscapeRight:
                orientation = .landscapeRight
            case .landscapeLeft:
                orientation = .landscapeLeft
            case .portraitUpsideDown:
                orientation = .portraitUpsideDown
            case .portrait:
                orientation = .portrait
            case .unknown:
                return
            }

            self.previewView.videoOrientation = orientation
            self.delegate?.videoOrientationDidChange(videoOrientation: orientation)
            self.setNeedsUpdateConstraints()
        }
    }
    
    @IBAction func queue_sessionRunning(){
        DispatchQueue.main.async {
            self.updateAppearance()
        }
    }
    
    private func updateAppearance(){
        self.previewView.alpha = self.error != nil ? 0 : 1

        if let error = self.error {
            self.previewView.isTemplateImageHidden = true
        } else if let capturedImage = self.capturedImage {
            self.previewView.isTemplateImageHidden = true
        } else {
            self.previewView.isTemplateImageHidden = false
        }
    }
    
    var capturedImage: UIImage? {
        get {
            return self.previewView.capturedImage
        }
        set {
            self.previewView.capturedImage = newValue
            self.updateAppearance()
        }
    }
    
    override func updateConstraints() {
        
        NSLayoutConstraint.deactivate(self.variableConstraints)
        self.variableConstraints.removeAll()

        let views : [String: UIView] = ["view" : self, "previewView": previewView]
        
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        
        self.variableConstraints = [NSLayoutConstraint(item: self.previewView,
                                                       attribute: .top,
                                                       relatedBy: .equal,
                                                       toItem: self,
                                                       attribute: .top,
                                                       multiplier: 1.0,
                                                       constant: 0),
                                    NSLayoutConstraint(item: self.previewView,
                                                       attribute: .left,
                                                       relatedBy: .equal,
                                                       toItem: self,
                                                       attribute: .left,
                                                       multiplier: 1.0,
                                                       constant: 0),
                                    NSLayoutConstraint(item: self.previewView,
                                                       attribute: .right,
                                                       relatedBy: .equal,
                                                       toItem: self,
                                                       attribute: .right,
                                                       multiplier: 1.0,
                                                       constant: 0),
                                    NSLayoutConstraint(item: self.previewView,
                                                       attribute: .bottom,
                                                       relatedBy: .equal,
                                                       toItem: self,
                                                       attribute: .bottom,
                                                       multiplier: 1.0,
                                                       constant: 0)]
        
        NSLayoutConstraint.activate(self.variableConstraints)
        super.updateConstraints()
    }
    
    var session: AVCaptureSession? {
        get {
            return self.previewView.session
        }
        set {
            self.previewView.session = newValue
            self.orientationDidChange()
        }
    }
    
    @IBAction func sessionWasInterrupted(notification: Notification){
        guard let reason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? AVCaptureSession.InterruptionReason else {return}
        if reason == AVCaptureSession.InterruptionReason.videoDeviceNotAvailableWithMultipleForegroundApps {
            self.error = ImageCaptureError.cameraUnavailable
        }
    }
    
    @IBAction func sessionInterruptionEnded(notification: Notification){
        self.error = nil
    }
    
}
