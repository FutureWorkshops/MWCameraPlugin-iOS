//
//  MWCameraPlugin.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 14/4/21.
//

import Foundation
import MobileWorkflowCore

public struct MWCameraPlugin: Plugin {
    public static var allStepsTypes: [StepType] {
        return MWCameraStepType.allCases
    }
}

public enum MWCameraStepType: String, StepType, CaseIterable {
    
    case qrCode = "io.mobileworkflow.qrcodescanner"
    case barcode = "io.mobileworkflow.barcodescanner"
    case videoCaptureModal = "io.mobileworkflow.VideoCaptureModal"
    case videoCapture = "io.mobileworkflow.VideoCapture"
    case imageCapture = "io.mobileworkflow.ImageCapture"
    
    public var typeName: String {
        return self.rawValue
    }
    
    public var stepClass: BuildableStep.Type {
        switch self {
        case .qrCode: return MWCameraQRCodeStep.self
        case .barcode: return MWBarcodeStep.self
        case .videoCaptureModal: return MWVideoCaptureModalStep.self
        case .videoCapture: return MWVideoCaptureInViewStep.self
        case .imageCapture: return MWImageCaptureStep.self
        }
    }
}
