//
//  MWQRCodeStep.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 2/12/20.
//

import Foundation
import MobileWorkflowCore

public struct MWCameraPlugin: MobileWorkflowPlugin {
    public static var allStepsTypes: [MobileWorkflowStepType] {
        return MWCameraStepType.allCases
    }
}

public enum MWCameraStepType: String, MobileWorkflowStepType, CaseIterable {
    
    case qrCode = "io.mobileworkflow.qrcodescanner"
    
    public var typeName: String {
        return self.rawValue
    }
    
    public var stepClass: MobileWorkflowStep.Type {
        switch self {
        case .qrCode: return MWCameraQRCodeStep.self
        }
    }
}

public class MWCameraQRCodeStep: ORKStep {
    
    override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func stepViewControllerClass() -> AnyClass {
        return MWQRCodeStepViewController.self
    }
}

extension MWCameraQRCodeStep: MobileWorkflowStep {
    public static func build(stepInfo: StepInfo, services: MobileWorkflowServices) throws -> Step {
        return MWCameraQRCodeStep(identifier: stepInfo.data.identifier)
    }
}

internal enum L10n {
    private static let LocalizationTable = "Localizable"
    private static var bundle: Bundle { Bundle(for: MWCameraQRCodeStep.self) }
    
    static func localisedString(key: String, fallback: String? = nil) -> String {
        print(bundle.bundleURL)
        return bundle.localizedString(forKey: key, value: fallback, table: LocalizationTable)
    }
    
    enum Camera {
        static let errorTitle = L10n.localisedString(key: "alert.error.title")
        static let errorMessage = L10n.localisedString(key: "alert.error.message")
        static let qrLabel = L10n.localisedString(key: "qr.label")
    }
}
