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
         isOptional: Bool?,
         session: Session,
         services: StepServices,
         theme: Theme) {
        self.imageURL = imageURL
        self.devicePosition = AVCaptureDevice.Position(stringValue: devicePosition)
        self.compressionQuality = compressionQuality ?? 1.0
        self.showGalleryOption = showGalleryOption ?? false
        self.session = session
        self.services = services
        super.init(
            identifier: identifier,
            isOptional: isOptional ?? false,
            theme: theme
        )
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
                                  isOptional: stepInfo.data.content["optional"] as? Bool,
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

public class CameraImageCaptureMetadata: StepMetadata {
    enum CodingKeys: CodingKey {
        case devicePosition
        case imageQuality
        case imageURL
        case optional
        case showGalleryOption
    }
    
    let devicePosition: String
    let imageQuality: String
    let imageURL: String?
    let optional: Bool?
    let showGalleryOption: Bool?
    
    init(id: String, title: String, devicePosition: String, imageQuality: String, imageURL: String?, optional: Bool?, showGalleryOption: Bool?, next: PushLinkMetadata?, links: [LinkMetadata]) {
        self.devicePosition = devicePosition
        self.imageQuality = imageQuality
        self.imageURL = imageURL
        self.optional = optional
        self.showGalleryOption = showGalleryOption
        super.init(id: id, type: "io.mobileworkflow.ImageCapture", title: title, next: next, links: links)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.devicePosition = try container.decode(String.self, forKey: .devicePosition)
        self.imageQuality = try container.decode(String.self, forKey: .imageQuality)
        self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        self.optional = try container.decodeIfPresent(Bool.self, forKey: .optional)
        self.showGalleryOption = try container.decodeIfPresent(Bool.self, forKey: .showGalleryOption)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.devicePosition, forKey: .devicePosition)
        try container.encode(self.imageQuality, forKey: .imageQuality)
        try container.encodeIfPresent(self.imageURL, forKey: .imageURL)
        try container.encodeIfPresent(self.optional, forKey: .optional)
        try container.encodeIfPresent(self.showGalleryOption, forKey: .showGalleryOption)
        try super.encode(to: encoder)
    }
}

public extension StepMetadata {
    static func cameraImageCapture(
        id: String,
        title: String,
        devicePosition: String,
        imageQuality: String,
        imageURL: String? = nil,
        optional: Bool? = nil,
        showGalleryOption: Bool? = nil,
        next: PushLinkMetadata? = nil,
        links: [LinkMetadata] = []
    ) -> CameraImageCaptureMetadata {
        cameraImageCapture(id: id, title: title, devicePosition: devicePosition, imageQuality: imageQuality, imageURL: imageURL, optional: optional, showGalleryOption: showGalleryOption, next: next, links: links)
    }
}
