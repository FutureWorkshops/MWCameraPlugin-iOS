//
//  MWVideoRecordingView.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 06/10/2021.
//

import UIKit
import AVFoundation
import AVKit
import MobileWorkflowCore

protocol MWVideoRecordingViewDelegate : AnyObject {
    func capturePressed(handler: (() -> Void)?)
    func stopCapturePressed(handler: (() -> Void)?)
    func retakePressed(handler: (() -> Void)?)
    func videoOrientationDidChange(videoOrientation: AVCaptureVideoOrientation)
    func cancel()
    func switchCamera()
}

final class MWVideoRecordingView : UIView {
    
    private var instruction: String? {
        didSet{
            self.instructionsLabel.text = self.instruction
            self.headerView.isHidden = self.instruction == nil
        }
    }
    
    private let videoCaptureStep: MWVideoCaptureStep
    
    weak var delegate: MWVideoRecordingViewDelegate?
    
    var videoFileURL: URL? {
        didSet{
            self.previewView.videoFileURL = videoFileURL
            self.updateAppearance()
        }
    }
    
    var error: Error? {
        didSet{
            self.updateAppearance()
        }
    }
    
    var recording: Bool = false {
        didSet{
            self.recordButton.isRecording = self.recording
            self.cancelButton.isEnabled = self.recording == false
            self.changeCameraButton.isEnabled = self.recording == false
            self.updateAppearance()
        }
    }
    
    var session: AVCaptureSession? {
        get{
            return self.previewView.session
        }
        set{
            self.previewView.session = newValue
            self.orientationDidChange()
        }
    }
    
    private lazy var previewView = MWVideoCaptureCameraPreviewView()
    
    private lazy var recordButton : RecordButton = {
        let recordButton = RecordButton()
        recordButton.tintColor = self.videoCaptureStep.theme.primaryTintColor
        recordButton.addTarget(self, action: #selector(self.recordButtonPressed), for: .touchUpInside)
        return recordButton
    }()
    
    private lazy var cancelButton : CustomButton = {
        let cancelButton = CustomButton()
        cancelButton.configureWithStyle(ButtonStyle.textOnly, theme: self.videoCaptureStep.theme)
        cancelButton.setTitle(L10n.VideoCaptureStep.cancelTitle, for: .normal)
        cancelButton.addTarget(self, action: #selector(self.cancel), for: .touchUpInside)
        cancelButton.contentHorizontalAlignment = .center
        return cancelButton
    }()
    
    private lazy var changeCameraButton : CustomButton = {
        let changeCameraButton = CustomButton()
        changeCameraButton.configureWithStyle(ButtonStyle.textOnly, theme: self.videoCaptureStep.theme)
        let imageConfig = UIImage.SymbolConfiguration(textStyle: .largeTitle)
        let image = UIImage(systemName: "arrow.2.circlepath", withConfiguration: imageConfig)
        changeCameraButton.setImage(image, for: .normal)
        changeCameraButton.contentHorizontalAlignment = .center
        changeCameraButton.addTarget(self, action: #selector(self.changeCamera), for: .touchUpInside)
        return changeCameraButton
    }()
    
    private var variableConstraints: [NSLayoutConstraint] = []
    private var timer: Timer?
    private var recordTime: TimeInterval = 0
    
    private lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.zeroFormattingBehavior = .pad
        dateComponentsFormatter.allowedUnits = [.minute, .second, .nanosecond]
        return dateComponentsFormatter
    }()
    
    private var capturePressesIgnored = false
    private var stopCapturePressesIgnored = false
    private var retakePressesIgnored = false
    
    var showControls: Bool = true {
        didSet{
            self.recordButton.isHidden = self.showControls == false
            self.cancelButton.isHidden = self.showControls == false
            self.changeCameraButton.isHidden = self.showControls == false || self.videoCaptureStep.deviceCamera != .any
        }
    }
    
    private lazy var instructionsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var headerView: UIView = {
        let headerView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.layer.cornerRadius = 10
        headerView.layer.masksToBounds = true
        headerView.isHidden = true
        headerView.contentView.addSubview(self.instructionsLabel)
        return headerView
    }()
    
    init(videoCaptureStep: MWVideoCaptureStep, frame: CGRect) {
        
        self.videoCaptureStep = videoCaptureStep
        
        super.init(frame: frame)
        
        self.registerObservers()
        
        self.setupUI()
    }
    
    private lazy var stackView : UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private func registerObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationDidChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.queueSessionRunning), name: NSNotification.Name.AVCaptureSessionDidStartRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionWasInterrupted), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: self.session)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionInterruptionEnded), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: self.session)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: self.session)
    }
    
    private func setupUI(){
        self.addSubview(self.previewView)
        
        self.addSubview(self.headerView)
        
        self.addSubview(self.cancelButton)
        
        self.addSubview(self.recordButton)
        
        self.addSubview(self.changeCameraButton)
        
        self.changeCameraButton.isHidden = self.videoCaptureStep.deviceCamera != .any
        
        self.updateConstraints()
        
        self.updateAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func queueSessionRunning(){

    }
    
    @IBAction func recordButtonPressed(){
        if self.recording {
            self.stopCapturePressed()
        }else{
            self.capturePressed()
        }
    }
    
    private var needsToRotate : Bool {
        guard self.videoCaptureStep.videoOrientation.supportsLandscape else {return false}
        switch self.window?.windowScene?.interfaceOrientation {
        case .landscapeRight, .landscapeLeft:
            return false
        default:
            return self.videoCaptureStep.videoOrientation == .landscape
        }
    }
    
    @IBAction func orientationDidChange(){
        DispatchQueue.main.async {
            
            var orientation: AVCaptureVideoOrientation = .portrait
            switch (self.window?.windowScene?.interfaceOrientation) {
            case .landscapeRight:
                orientation = .landscapeRight
            case .landscapeLeft:
                orientation = .landscapeLeft
            case .portraitUpsideDown:
                orientation = .portraitUpsideDown
            case .portrait:
                orientation = .portrait
            case .unknown, .none:
                // Do nothing in these cases, since we don't need to change display orientation.
                return
            case .some(_):
                return
            }
            self.previewView.videoOrientation = orientation
            self.delegate?.videoOrientationDidChange(videoOrientation: orientation)
            self.updateAppearance()
            self.setNeedsUpdateConstraints()
        }
    }

    
    private func updateAppearance() {

        self.previewView.alpha = self.error != nil ? 0 : 1;
        
        if self.error != nil {
            self.instruction = self.error?.localizedDescription
            
        } else if self.recording {
            self.instruction = nil
            
            self.recordTime = 0.0
            
            self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateRecordTime), userInfo: nil, repeats: true)

        } else {

            self.instruction =  self.needsToRotate ? L10n.VideoCaptureStep.rotateDevice : nil
            
            self.recordButton.isEnabled = self.needsToRotate == false
    
        }
    }
    
    override func updateConstraints() {
        
        NSLayoutConstraint.deactivate(self.variableConstraints)
        self.variableConstraints.removeAll()
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.recordButton.translatesAutoresizingMaskIntoConstraints = false
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
        self.changeCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        let trailingConstraint = self.headerView.trailingAnchor.constraint(greaterThanOrEqualTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -32)
        trailingConstraint.priority = .defaultLow

        self.variableConstraints.append(contentsOf: [
            self.instructionsLabel.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 12),
            self.instructionsLabel.trailingAnchor.constraint(equalTo: self.headerView.trailingAnchor, constant: -12),
            self.instructionsLabel.topAnchor.constraint(equalTo: self.headerView.topAnchor, constant: 12),
            self.instructionsLabel.bottomAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: -12),

            self.headerView.leadingAnchor.constraint(greaterThanOrEqualTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            trailingConstraint,
            self.headerView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 32),
            self.headerView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
             NSLayoutConstraint(item: self.previewView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0),
             
             NSLayoutConstraint(item: self.previewView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0),
             NSLayoutConstraint(item: self.previewView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.previewView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.recordButton, attribute: .bottom, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -10.0),
            NSLayoutConstraint(item: self.recordButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.recordButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 90.0),
            NSLayoutConstraint(item: self.recordButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 90.0),
            NSLayoutConstraint(item: self.cancelButton, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 10.0),
            NSLayoutConstraint(item: self.cancelButton, attribute: .right, relatedBy: .equal, toItem: self.recordButton, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.cancelButton, attribute: .centerY, relatedBy: .equal, toItem: self.recordButton, attribute: .centerY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.changeCameraButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.changeCameraButton, attribute: .left, relatedBy: .equal, toItem: self.recordButton, attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.changeCameraButton, attribute: .centerY, relatedBy: .equal, toItem: self.recordButton, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        ])
        
        NSLayoutConstraint.activate(self.variableConstraints)
        
        super.updateConstraints()
    }
    
    @IBAction func retakePressed() {
        // If we are still waiting for the delegate to complete, ignore futher presses
        if self.retakePressesIgnored {
            return
        }

        // Ignore futher presses until the delegate completes
        self.retakePressesIgnored = true

        // Tell the delegate to start capturing again
        self.delegate?.retakePressed(handler: { [weak self] in
            // Stop ignoring presses
            self?.retakePressesIgnored = false
        })
    }
    
    @IBAction func capturePressed() {
        // If we are still waiting for the delegate to complete, ignore futher presses
        if self.capturePressesIgnored {
            return
        }

        // Ignore futher presses until the delegate completes
        self.capturePressesIgnored = true

        // Capture the video via the delegate
        self.delegate?.capturePressed(handler: { [weak self] in
            // Stop ignoring presses
            self?.capturePressesIgnored = false
        })
    }
    
    @IBAction func stopCapturePressed() {
        // If we are still waiting for the delegate to complete, ignore futher presses
        if self.stopCapturePressesIgnored {
            return
        }

        // Ignore futher presses until the delegate completes
        self.stopCapturePressesIgnored = true

        // Invalidate timer.
        self.timer?.invalidate()

        // Stop the video capture via the delegate
        self.delegate?.stopCapturePressed(handler: { [weak self] in
            // Stop ignoring presses
            self?.stopCapturePressesIgnored = false
        })

    }
    
    @IBAction func updateRecordTime(_ timer: Timer) {
        self.recordTime += timer.timeInterval
        
         if self.recordTime >= self.videoCaptureStep.duration {
            self.stopCapturePressed()
         }else if self.recording == false {
             self.timer?.invalidate()
            self.updateAppearance()
        } else {
            let remainingTime = self.videoCaptureStep.duration - recordTime
            self.instruction = self.dateComponentsFormatter.string(from: remainingTime)
        }
    }
    
    @IBAction func cancel() {
        self.delegate?.cancel()
    }
    
    @IBAction func changeCamera() {
        self.delegate?.switchCamera()
    }
    
    @IBAction func sessionWasInterrupted(_ notification: Notification?) {
        let reason = AVCaptureSession.InterruptionReason(rawValue: (notification?.userInfo?[AVCaptureSessionInterruptionReasonKey] as? NSNumber)?.intValue ?? 0)
        if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
            self.error = VideoCaptureError.cameraUnavailable
        }
        self.previewView.session?.stopRunning()
    }
    
    @IBAction func sessionInterruptionEnded(_ notification: Notification?) {
        self.error = nil
    }
    
    @IBAction func didBecomeActive(){
        self.retakePressed()
    }
    
}
