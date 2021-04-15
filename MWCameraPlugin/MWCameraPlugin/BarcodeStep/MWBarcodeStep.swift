//
//  MWBarcodeStep.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 14/4/21.
//

import Foundation
import MobileWorkflowCore

public class MWBarcodeStep: ORKStep {
    
    override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func stepViewControllerClass() -> AnyClass {
        return MWBarcodeStepViewController.self
    }
}

extension MWBarcodeStep: MobileWorkflowStep {
    public static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        return MWBarcodeStep(identifier: stepInfo.data.identifier)
    }
}
