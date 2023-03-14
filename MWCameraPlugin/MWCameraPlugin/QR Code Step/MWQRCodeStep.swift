//
//  MWQRCodeStep.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 2/12/20.
//

import Foundation
import MobileWorkflowCore

public class MWCameraQRCodeStep: MWStep {
    
    public init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func instantiateViewController() -> StepViewController {
        MWQRCodeStepViewController(step: self)
    }
}

extension MWCameraQRCodeStep: BuildableStep {
    
    public static var mandatoryCodingPaths: [CodingKey] { [] }
    
    public static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        return MWCameraQRCodeStep(identifier: stepInfo.data.identifier)
    }
}

public class CameraQRCodeScannerMetadata: StepMetadata {
    
    public init(id: String, title: String, next: PushLinkMetadata?, links: [LinkMetadata]) {
        super.init(id: id, type: "io.mobileworkflow.qrcodescanner", title: title, next: next, links: links)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}

public extension StepMetadata {
    static func cameraQRCodeScanner(
        id: String,
        title: String,
        next: PushLinkMetadata? = nil,
        links: [LinkMetadata] = []
    ) -> CameraQRCodeScannerMetadata {
        CameraQRCodeScannerMetadata(id: id, title: title, next: next, links: links)
    }
}
