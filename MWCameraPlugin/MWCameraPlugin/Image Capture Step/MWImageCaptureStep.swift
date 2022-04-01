//
//  MWImageCaptureStep.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 07/12/2021.
//

import UIKit
import MobileWorkflowCore
import AVFoundation

final class MWImageCaptureStep: MWStep {
    
    public var imageURL: String?
    public let session: Session
    public let services: StepServices
    
    let devicePosition: AVCaptureDevice.Position
    let compressionQuality: CGFloat
    let showGalleryOption: Bool
    let captureRaw: Bool = false
    
    init(identifier: String,
         imageURL: String?,
         devicePosition: String?,
         compressionQuality: CGFloat?,
         showGalleryOption: Bool?,
         session: Session,
         services: StepServices,
         theme: Theme) {
        self.imageURL = imageURL
        self.devicePosition = AVCaptureDevice.Position(stringValue: devicePosition)
        self.compressionQuality = compressionQuality ?? 1.0
        self.showGalleryOption = showGalleryOption ?? false
        self.session = session
        self.services = services
        super.init(identifier: identifier, theme: theme)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func instantiateViewController() -> StepViewController {
        return MWImageCaptureViewController(step: self)
    }
}

extension MWImageCaptureStep: BuildableStep {
    
    public static var mandatoryCodingPaths: [CodingKey] { [] }
    
    static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        
        return MWImageCaptureStep(identifier: stepInfo.data.identifier,
                                  imageURL: stepInfo.data.content["imageURL"] as? String,
                                  devicePosition: stepInfo.data.content["devicePosition"] as? String,
                                  compressionQuality: stepInfo.data.content["imageQuality"] as? CGFloat,
                                  showGalleryOption: stepInfo.data.content["showGalleryOption"] as? Bool,
                                  session: stepInfo.session,
                                  services: services,
                                  theme: stepInfo.context.theme)
  
    }
}

extension AVCaptureDevice.Position {
    
    init(stringValue: String?){
        if let stringValue = stringValue, let rawValue = Int(stringValue), let devicePosition = AVCaptureDevice.Position(rawValue: rawValue) {
            self = devicePosition
        }else{
            self = .back
        }
    }
    
}
