//
//  MWQRCodeStepViewController.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 2/12/20.
//

import UIKit
import MobileWorkflowCore

public class MWQRCodeStepViewController: MWStepViewController {
    
    public override var titleMode: StepViewControllerTitleMode { .customOrNone }
    
    //MARK: Private properties
    private var qrCodeStep: MWCameraQRCodeStep { self.mwStep as! MWCameraQRCodeStep }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let qrScanner = _MWQRCodeStepViewController() { [weak self] codeFound in
            guard let self = self else { return }
            let result = QRCodeResult(identifier: self.qrCodeStep.identifier, codeFound: codeFound)
            self.addStepResult(result)
            self.goForward()
        }
        self.addCovering(childViewController: qrScanner)
    }
}

private class _MWQRCodeStepViewController: QRScannerViewController {
    
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
