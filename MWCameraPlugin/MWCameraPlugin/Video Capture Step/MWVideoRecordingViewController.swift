//
//  MWVideoRecordingViewController.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 06/10/2021.
//

import UIKit
import AVFoundation
import MobileWorkflowCore

protocol MWVideoRecordingViewControllerDelegate: AnyObject {
    func cancel()
    func didFinishRecordingTo(videoFileURL: URL?)
    func stateDidChange(isRecording: Bool)
}

final class MWVideoRecordingViewController: UIViewController {
    
    weak var delegate: MWVideoRecordingViewControllerDelegate?
    
    private let videoRecordingView: MWVideoRecordingView
    private let sessionQueue: DispatchQueue = DispatchQueue(label: "session queue")
    private var captureSession: AVCaptureSession?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var fileURL: URL?
    private var ephemeralFileURL: URL?
    private var captureDevice: AVCaptureDevice?
    private let mediaType: AVMediaType = .video
    public var recording: Bool = false {
        didSet{
            self.videoRecordingView.recording = self.recording
            self.delegate?.stateDidChange(isRecording: self.recording)
        }
    }
    
    public override var shouldAutorotate: Bool {
        return self.recording == false
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.videoCaptureStep.videoOrientation.supportsLandscape ? .all : .portrait
    }
    
    private let videoCaptureStep: MWVideoCaptureStep
    private let outputPath: URL?
    private lazy var devicePosition : AVCaptureDevice.Position = self.videoCaptureStep.deviceCamera.position
    private var didCancel: Bool = false
    
    init(videoCaptureStep: MWVideoCaptureStep, outputPath: URL?, showControls: Bool = true) {
        self.videoCaptureStep = videoCaptureStep
        self.outputPath = outputPath
        
        self.videoRecordingView = MWVideoRecordingView(videoCaptureStep: videoCaptureStep, frame: .zero)
        self.videoRecordingView.showControls = showControls
        super.init(nibName: nil, bundle: nil)
        
        self.videoRecordingView.delegate = self
        self.view.addSubview(self.videoRecordingView)
        
        self.setUpConstaints()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        
        self.setupVideoCapture()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let fileURL = self.fileURL {
            self.setFileURL(fileURL)
        }else{
            self.sessionQueue.async {
                self.startRunningCaptureSession()
            }
        }
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if self.captureSession?.isRunning == true {
            self.sessionQueue.async {
                self.captureSession?.stopRunning()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    private func setUpConstaints(){

        let constraints = [NSLayoutConstraint(item: self.videoRecordingView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: self.videoRecordingView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: self.videoRecordingView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: self.videoRecordingView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0.0)]
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
    func setupVideoCapture(){
        self.sessionQueue.async {
            self.queueSetupCaptureSession()
            self.startRunningCaptureSession()
        }
    }
    
    private func configureTorchMode(){
        guard let device = self.captureDevice, device.isTorchModeSupported(self.videoCaptureStep.torchMode) else {return}
        do {
            try device.lockForConfiguration()
            device.torchMode = self.videoCaptureStep.torchMode
            device.unlockForConfiguration()
        }catch {
            self.show(error)
        }
    }
    
    private func queueSetupCaptureSession(){
        self.captureSession = AVCaptureSession()
        
        self.captureSession?.beginConfiguration()
        
        self.captureSession?.inputs.forEach({self.captureSession?.removeInput($0)})
        
        self.captureSession?.automaticallyConfiguresCaptureDeviceForWideColor = false
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: self.mediaType, position: devicePosition)
        
        self.captureDevice = discoverySession.devices.first
        
        if let device = self.captureDevice {
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                let movieFileOutput = AVCaptureMovieFileOutput()
//                movieFileOutput.maxRecordedDuration = CMTimeMakeWithSeconds(self.videoCaptureStep.duration, preferredTimescale: 30);
                movieFileOutput.movieFragmentInterval = CMTime.invalid // MP4 apparently does not support fragments so after first 10 second fragment the audio gets lost, so disabling them...
                
                if self.captureSession?.canAddInput(input) == true && self.captureSession?.canAddOutput(movieFileOutput) == true {
                    
                    self.captureSession?.addInput(input)
                    self.captureSession?.addOutput(movieFileOutput)
                    
                    if self.videoCaptureStep.audioMute == false, let audioDevice = AVCaptureDevice.default(for: .audio) {
                        do {
                            let audioInput = try AVCaptureDeviceInput.init(device: audioDevice)
                            if self.captureSession?.canAddInput(audioInput) == true {
                                self.captureSession?.addInput(audioInput)
                            }
                        }catch {
                            self.show(error)
                        }
                    }
                    
                    self.movieFileOutput = movieFileOutput

                }else{
                    DispatchQueue.main.async {
                        self.handlError(VideoCaptureError.captureErrorNoPermission)
                    }
                    self.captureSession = nil
                }
                
            }catch {
                self.show(error)
            }
            
        }else{
            
            DispatchQueue.main.async {
                self.handlError(VideoCaptureError.captureErrorCameraNotFound)
            }
            self.captureSession = nil
        }
        
        self.captureSession?.commitConfiguration()
        
        self.videoRecordingView.session = self.captureSession
    }
    
    private func handlError(_ error: Error) {
        if self.captureSession?.isRunning == true {
            self.sessionQueue.async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
        
        self.captureSession = nil
        self.movieFileOutput = nil
        self.videoRecordingView.session = nil
        self.videoRecordingView.videoFileURL = nil
        self.fileURL = nil
        
        self.videoRecordingView.error = error
    }
    
    private func setFileURL(_ fileURL: URL?){
        self.updateFileURL(fileURL, notify: true)
    }
    
    private func updateFileURL(_ fileURL: URL?, notify: Bool = false){
        self.fileURL = fileURL
        self.ephemeralFileURL = FileStreamManager.createEphemeralURL(for: fileURL)
        if notify {
            self.videoRecordingView.videoFileURL = self.ephemeralFileURL
        }
    }
    
    private func cleanRecording(){
        let fileManager = FileManager.default
        if let ephemeralFileURL = self.ephemeralFileURL, fileManager.fileExists(atPath: ephemeralFileURL.path) {
            do {
                try fileManager.removeItem(atPath: ephemeralFileURL.path)
            } catch {
                self.show(error)
            }
        }
        
        if let fileURL = self.fileURL, fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(atPath: fileURL.path)
            } catch {
                self.show(error)
            }
        }
    }
    
    func startAgain(){
        self.videoRecordingView.retakePressed()
    }
    
    func startRecording(){
        self.videoRecordingView.capturePressed()
    }
    
    func stopRecording(){
        self.videoRecordingView.stopCapturePressed()
    }
    
    private func startRunningCaptureSession(){
        self.captureSession?.startRunning()
        //Starting session turns off the torch, so set it after session starts
        self.configureTorchMode()
    }
    
}



extension MWVideoRecordingViewController : MWVideoRecordingViewDelegate {
    
    func retakePressed(handler: (() -> Void)?) {
        self.sessionQueue.async {
            self.startRunningCaptureSession()
            DispatchQueue.main.async {
                self.setFileURL(nil)
                handler?()
            }
        }
    }
    
    func capturePressed(handler: (() -> Void)?) {
        self.sessionQueue.async {
            
            self.updateFileURL(self.outputPath)
            self.cleanRecording()
            
            let connection = self.movieFileOutput?.connection(with: self.mediaType)
            if connection?.isActive == true, let ephemeralFileURL = self.ephemeralFileURL {
                self.movieFileOutput?.startRecording(to: ephemeralFileURL, recordingDelegate: self)
                DispatchQueue.main.async {
                    handler?()
                }
            }else{
                DispatchQueue.main.async {
                    handler?()
                    self.handlError(VideoCaptureError.captureErrorNoPermission)
                }
            }
        }
    }
    
    func stopCapturePressed(handler: (() -> Void)?) {
        
        if self.movieFileOutput?.isRecording == true {
            self.sessionQueue.async {
                self.movieFileOutput?.stopRecording()
                DispatchQueue.main.async {
                    handler?()
                }
            }
        }else{
            DispatchQueue.main.async {
                handler?()
            }
        }
    }
    
    func videoOrientationDidChange(videoOrientation: AVCaptureVideoOrientation) {
        if let connections = self.movieFileOutput?.connections, connections.isEmpty == false {
            connections.first?.videoOrientation = videoOrientation
        }
    }
    
    func cancel() {
        
        self.didCancel = true
        
        self.delegate?.cancel()
    }
    
    func switchCamera(){
        guard self.videoCaptureStep.deviceCamera == .any, self.recording == false else {return }
        self.devicePosition = self.devicePosition.otherPosition
        self.setupVideoCapture()
    }

}

extension MWVideoRecordingViewController : AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        self.recording = true
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        self.recording = false
        
        if let error = error {
            self.videoRecordingView.error = error
            return
        }
        
        guard self.didCancel == false else {return}
        
        self.setFileURL(FileStreamManager.extractOriginalFileURL(from: outputFileURL))
        
        if let ephemeralFileURL = self.ephemeralFileURL, let fileURL = self.fileURL {
            let fileStreamManager = FileStreamManager(origin: FileManager.default, destination: FileManager.default)
            fileStreamManager.copyFile(from: ephemeralFileURL, to: fileURL)
        }
        
        self.delegate?.didFinishRecordingTo(videoFileURL: fileURL)
        
    }

}

extension DeviceCamera {
    
    fileprivate var position: AVCaptureDevice.Position {
        switch self {
        case .any: return .back
        case .front: return .front
        case .back: return .back
        }
    }
    
}

extension AVCaptureDevice.Position {
    
    fileprivate var otherPosition: AVCaptureDevice.Position {
        switch self {
        case .back: return .front
        case .front: return .back
        case .unspecified: return .front
        }
    }
    
}
