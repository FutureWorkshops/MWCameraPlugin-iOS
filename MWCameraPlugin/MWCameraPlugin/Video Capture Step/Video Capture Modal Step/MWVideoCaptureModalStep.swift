//
//  MWVideoCaptureStep.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 23/09/2021.
//

import Foundation
import AVFoundation
import MobileWorkflowCore
import UIKit

final class MWVideoCaptureModalStep: MWStep, InstructionStep, MWVideoCaptureStep {
    
    public var imageURL: String?
    public var image: UIImage?
    public let session: Session
    public let services: StepServices
    
    let duration: TimeInterval
    let audioMute: Bool
    let torchMode: AVCaptureDevice.TorchMode
    let deviceCamera: DeviceCamera
    let videoOrientation: VideoOrientation
    let instructionsText: String?
    
    init(identifier: String,
         duration: Int?,
         audioMute: Bool?,
         torchMode: String?,
         deviceCamera: String?,
         videoOrientation: String?,
         instructionsText: String?,
         imageURL: String?,
         session: Session,
         services: StepServices,
         theme: Theme) {
        self.duration = TimeInterval(duration ?? 120)
        self.audioMute = audioMute ?? false
        self.torchMode = AVCaptureDevice.TorchMode(stringValue: torchMode)
        self.deviceCamera = DeviceCamera(rawValue: deviceCamera ?? "") ?? .back
        self.videoOrientation = VideoOrientation(rawValue: videoOrientation ?? "") ?? .portrait
        self.instructionsText = instructionsText
        self.imageURL = imageURL
        self.session = session
        self.services = services
        super.init(identifier: identifier, theme: theme)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func instantiateViewController() -> StepViewController {
        return MWVideoCaptureViewController(step: self)
    }
}

extension MWVideoCaptureModalStep: BuildableStep {
    static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        return MWVideoCaptureModalStep(identifier: stepInfo.data.identifier,
                                  duration: stepInfo.data.content["duration"] as? Int,
                                  audioMute: stepInfo.data.content["audioMute"] as? Bool,
                                  torchMode: stepInfo.data.content["torchMode"] as? String,
                                  deviceCamera: stepInfo.data.content["deviceCamera"] as? String,
                                  videoOrientation: stepInfo.data.content["videoOrientation"] as? String,
                                  instructionsText: stepInfo.data.content["instructionsText"] as? String,
                                  imageURL: stepInfo.data.content["imageURL"] as? String,
                                  session: stepInfo.session,
                                  services: services,
                                  theme: stepInfo.context.theme)
  
    }
}

