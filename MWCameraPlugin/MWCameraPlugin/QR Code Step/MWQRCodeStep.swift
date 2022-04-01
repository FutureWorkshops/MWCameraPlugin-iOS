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
