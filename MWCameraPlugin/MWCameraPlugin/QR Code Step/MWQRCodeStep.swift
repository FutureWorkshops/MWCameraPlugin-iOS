//
//  MWQRCodeStep.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 2/12/20.
//

import Foundation
import MobileWorkflowCore

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
        return bundle.localizedString(forKey: key, value: fallback, table: LocalizationTable)
    }
    
    enum Camera {
        static let errorTitle = L10n.localisedString(key: "alert.error.title")
        static let errorMessage = L10n.localisedString(key: "alert.error.message")
        static let qrLabel = L10n.localisedString(key: "qr.label")
    }
}
