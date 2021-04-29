//
//  MWBarcodeStep.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 14/4/21.
//

import UIKit
import MobileWorkflowCore

public class MWBarcodeStep: MWStep {
    
    init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func instantiateViewController() -> StepViewController {
        MWBarcodeStepViewController(step: self)
    }
}

extension MWBarcodeStep: BuildableStep {
    public static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        return MWBarcodeStep(identifier: stepInfo.data.identifier)
    }
}
