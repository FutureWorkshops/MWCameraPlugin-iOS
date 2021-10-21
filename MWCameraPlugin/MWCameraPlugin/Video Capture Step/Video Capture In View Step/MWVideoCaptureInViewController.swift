//
//  MWVideoCaptureInViewController.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 13/10/2021.
//

import UIKit
import AVFoundation
import MobileWorkflowCore

final class MWVideoCaptureInViewController: MWContentStepViewController {
    
    private lazy var playerViewController : AVPlayerViewController = {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        playerViewController.allowsPictureInPicturePlayback = false
        playerViewController.view.backgroundColor = .black
        playerViewController.view.isHidden = true
        return playerViewController
    }()
    
    private lazy var videoRecordingViewController : MWVideoRecordingViewController = {
        let videoRecordingViewController = MWVideoRecordingViewController(videoCaptureStep: self.videoCaptureStep,
                                                                          outputPath: self.outputPath,
                                                                          showControls: false)
        videoRecordingViewController.delegate = self
        return videoRecordingViewController
    }()
    
    private var error: Error? {
        didSet{
            if let error = self.error {
                self.show(error)
            }
            self.configureNavigationFooter()
        }
    }
    
    private var fileURL: URL? {
        didSet{
            self.configureNavigationFooter()
            self.playerViewController.view.isHidden = self.fileURL == nil
            if let videoFileURL = self.fileURL {
                let item = AVPlayerItem(url: videoFileURL)
                self.playerViewController.player = AVPlayer(playerItem: item)
            }
        }
    }
    
    private var outputPath: URL? {
        return self.outputDirectory?.appendingPathComponent(self.videoCaptureStep.fileName)
    }

    private var videoCaptureStep: MWVideoCaptureInViewStep {
        return self.mwStep as! MWVideoCaptureInViewStep
    }
    
    private func setUpConstaints(){

        guard let playerView = self.playerViewController.view, let recordingView = self.videoRecordingViewController.view else {return}
        
        playerView.translatesAutoresizingMaskIntoConstraints = false
        recordingView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [NSLayoutConstraint(item: playerView, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: playerView, attribute: .left, relatedBy: .equal, toItem: self.contentView, attribute: .left, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: playerView, attribute: .right, relatedBy: .equal, toItem: self.contentView, attribute: .right, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: playerView, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: recordingView, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0.0),
                            NSLayoutConstraint(item: recordingView, attribute: .left, relatedBy: .equal, toItem: self.contentView, attribute: .left, multiplier: 1.0, constant: 0.0),
                            NSLayoutConstraint(item: recordingView, attribute: .right, relatedBy: .equal, toItem: self.contentView, attribute: .right, multiplier: 1.0, constant: 0.0),
                            NSLayoutConstraint(item: recordingView, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0)]
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted == false {
                    self?.error = VideoCaptureError.captureErrorNoPermission
                }
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        self.playerViewController.player?.pause()
        
        super.viewWillDisappear(animated)
    }
    
    private func setupUI() {
        
        self.title = self.mwStep.title
        
        addChild(self.videoRecordingViewController)
        self.view.addSubview(self.videoRecordingViewController.view)
        self.videoRecordingViewController.didMove(toParent: self)
        
        self.view.addSubview(self.playerViewController.view)
        
        self.configureNavigationFooter()

        self.setUpConstaints()
        
    }
    
    private func configureNavigationFooter() {
        
        let skipButton = self.videoCaptureStep.isOptional ? ButtonConfig(isEnabled: true,
                                                                         style: .textOnly,
                                                                         title: L10n.VideoCaptureStep.skipButtonTitle,
                                                                         action: self.goForward) : nil
        
        if self.videoRecordingViewController.recording {
            
            self.navigationFooterConfig = NavigationFooterView.Config(
                primaryButton: ButtonConfig(isEnabled: true, style: .primary, title: L10n.VideoCaptureStep.stopRecording, action: self.stopRecording),
                secondaryButton: nil,
                hasBlurredBackground: false
            )
            
        } else if self.fileURL != nil {
            
            self.navigationFooterConfig = NavigationFooterView.Config(
                primaryButton: ButtonConfig(isEnabled: true, style: .primary, title: L10n.VideoCaptureStep.nextButtonTitle, action: self.goForward),
                secondaryButton: ButtonConfig(isEnabled: true, style: .textOnly, title: L10n.VideoCaptureStep.startAgain, action: self.startAgain),
                hasBlurredBackground: false
            )
        
        } else {

            self.navigationFooterConfig = NavigationFooterView.Config(
                primaryButton: ButtonConfig(isEnabled: self.error == nil, style: .primary, title: L10n.VideoCaptureStep.startRecording, action: self.startRecording),
                secondaryButton: skipButton,
                hasBlurredBackground: false
            )
        }
        
    }
    
    @IBAction func startAgain(){
        self.fileURL = nil
        self.videoRecordingViewController.startAgain()
    }
    
    @IBAction func startRecording(){
        self.videoRecordingViewController.startRecording()
    }
    
    @IBAction func stopRecording(){
        self.videoRecordingViewController.stopRecording()
    }
    
}

extension MWVideoCaptureInViewController : MWVideoRecordingViewControllerDelegate {
    
    func cancel(){
        
    }
    
    func didFinishRecordingTo(videoFileURL: URL?) {
        
        self.fileURL = videoFileURL
        
        if let fileURL = self.fileURL {
            let fileResult = self.videoCaptureStep.fileResult(fileURL)
            self.addStepResult(fileResult)
        }
        
    }
    
    func stateDidChange(isRecording: Bool){
        self.configureNavigationFooter()
    }
    
}
