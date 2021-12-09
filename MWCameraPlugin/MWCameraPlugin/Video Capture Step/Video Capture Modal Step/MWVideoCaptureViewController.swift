//
//  MWVideoCaptureViewController.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 23/09/2021.
//

import UIKit
import AVFoundation
import MobileWorkflowCore

final class MWVideoCaptureViewController: MWInstructionStepViewController {
    
    private lazy var playerViewController : AVPlayerViewController = {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        playerViewController.allowsPictureInPicturePlayback = false
        playerViewController.view.backgroundColor = .black
        playerViewController.view.isHidden = true
        return playerViewController
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

    private var videoCaptureStep: MWVideoCaptureModalStep {
        return self.mwStep as! MWVideoCaptureModalStep
    }
    
    private func setUpConstaints(){

        guard let playerView = self.playerViewController.view else {return}
        
        playerView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [NSLayoutConstraint(item: playerView, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: playerView, attribute: .left, relatedBy: .equal, toItem: self.contentView, attribute: .left, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: playerView, attribute: .right, relatedBy: .equal, toItem: self.contentView, attribute: .right, multiplier: 1.0, constant: 0.0),
                           NSLayoutConstraint(item: playerView, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0)]
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
    init(step: Step) {
        
        super.init(instructionStep: step as! MWVideoCaptureModalStep)
        
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        self.view.addSubview(self.playerViewController.view)
        self.configureNavigationFooter()
        self.configureWithTitle(self.mwStep.title ?? "",
                                body: self.videoCaptureStep.instructionsText ?? "",
                                navigationFooterConfig: self.navigationFooterConfig)
        self.setUpConstaints()
        
    }
    
    private func configureNavigationFooter() {
        
        let skipButton = self.videoCaptureStep.isOptional ? ButtonConfig(isEnabled: true,
                                                                         style: .textOnly,
                                                                         title: L10n.VideoCaptureStep.skipButtonTitle,
                                                                         action: self.goForward) : nil
        
        if self.fileURL != nil {
            
            self.navigationFooterConfig = NavigationFooterView.Config(
                primaryButton: ButtonConfig(isEnabled: true, style: .primary, title: L10n.VideoCaptureStep.nextButtonTitle, action: self.goForward),
                secondaryButton: ButtonConfig(isEnabled: true, style: .textOnly, title: L10n.VideoCaptureStep.retakeVideo, action: self.openCamera),
                hasBlurredBackground: false
            )
        
        } else {

            self.navigationFooterConfig = NavigationFooterView.Config(
                primaryButton: ButtonConfig(isEnabled: self.error == nil, style: .primary, title: L10n.VideoCaptureStep.openCamera, action: self.openCamera),
                secondaryButton: skipButton,
                hasBlurredBackground: false
            )
        }
        
    }
    
    func openCamera() {
        let videoRecordingViewController = MWVideoRecordingViewController(videoCaptureStep: self.videoCaptureStep,
                                                                          outputPath: self.outputPath)
        videoRecordingViewController.delegate = self
        videoRecordingViewController.modalPresentationStyle = .fullScreen
        self.present(videoRecordingViewController, animated: true, completion: nil)
    }
    
}

extension MWVideoCaptureViewController : MWVideoRecordingViewControllerDelegate {
    
    func stateDidChange(isRecording: Bool){
        
    }
    
    func cancel(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func didFinishRecordingTo(videoFileURL: URL?) {
        self.dismiss(animated: true, completion: nil)
        
        self.fileURL = videoFileURL
        
        if let fileURL = self.fileURL {
            let fileResult = self.videoCaptureStep.fileResult(fileURL)
            self.addStepResult(fileResult)
        }
        
    }
    
}

