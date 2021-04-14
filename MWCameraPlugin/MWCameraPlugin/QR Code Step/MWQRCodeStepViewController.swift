//
//  MWQRCodeStepViewController.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 2/12/20.
//

import UIKit
import Foundation
import AVFoundation
import MobileWorkflowCore

public class MWQRCodeStepViewController: ORKStepViewController {
    
    //MARK: Private properties
    private var qrCodeStep: MWCameraQRCodeStep {
        guard let qrCodeStep = self.step as? MWCameraQRCodeStep else { preconditionFailure("Unexpected step type. Expecting \(String(describing: MWCameraQRCodeStep.self)), got \(String(describing: type(of: self.step)))") }
        return qrCodeStep
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let qrScanner = _MWQRCodeStepViewController() { [weak self] codeFound in
            guard let self = self else { return }
            let result = MWBarcodeResult(identifier: self.qrCodeStep.identifier, codeFound: codeFound)
            self.addResult(result)
            self.goForward()
        }
        self.addCovering(childViewController: qrScanner)
    }
    
}

private class _MWQRCodeStepViewController: MobileWorkflowQRScannerViewController {
    
    override var instructionsText: String {
        get { L10n.Camera.qrLabel }
        set {  }
    }
    
    private let completion: (String) -> Void
    
    init(completion: @escaping (String) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func found(code: String) {
        self.completion(code)
    }
}
