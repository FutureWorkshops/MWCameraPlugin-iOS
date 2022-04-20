//
//  MWVideoCaptureInViewStep.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 13/10/2021.
//

import Foundation
import AVFoundation
import MobileWorkflowCore

final class MWVideoCaptureInViewStep: MWStep, MWVideoCaptureStep {
    
    public let session: Session
    public let services: StepServices
    
    let duration: TimeInterval
    let audioMute: Bool
    let torchMode: AVCaptureDevice.TorchMode
    let deviceCamera: DeviceCamera
    let videoOrientation: VideoOrientation = .portrait
    
    init(identifier: String,
         duration: Int?,
         audioMute: Bool?,
         torchMode: String?,
         deviceCamera: String?,
         session: Session,
         services: StepServices,
         theme: Theme) {
        self.duration = TimeInterval(duration ?? 120)
        self.audioMute = audioMute ?? false
        self.torchMode = AVCaptureDevice.TorchMode(stringValue: torchMode)
        self.deviceCamera = DeviceCamera(rawValue: deviceCamera ?? "") ?? .back
        self.session = session
        self.services = services
        super.init(identifier: identifier, theme: theme)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func instantiateViewController() -> StepViewController {
        return MWVideoCaptureInViewController(step: self)
    }
}

extension MWVideoCaptureInViewStep: BuildableStep {
    
    static var mandatoryCodingPaths: [CodingKey] { [] }
    
    static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        return MWVideoCaptureInViewStep(identifier: stepInfo.data.identifier,
                                        duration: stepInfo.data.content["duration"] as? Int,
                                        audioMute: stepInfo.data.content["audioMute"] as? Bool,
                                        torchMode: stepInfo.data.content["torchMode"] as? String,
                                        deviceCamera: stepInfo.data.content["deviceCamera"] as? String,
                                        session: stepInfo.session,
                                        services: services,
                                        theme: stepInfo.context.theme)
  
    }
}
