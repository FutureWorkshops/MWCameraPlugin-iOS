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

extension MWCameraQRCodeStep: BuildableStep {
    public static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        return MWCameraQRCodeStep(identifier: stepInfo.data.identifier)
    }
}
