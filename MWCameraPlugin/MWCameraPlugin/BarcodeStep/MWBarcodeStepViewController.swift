//
//  MWBarcodeStepViewController.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 14/4/21.
//

import Foundation
import AVKit
import MobileWorkflowCore

public class MWBarcodeStepViewController: MWStepViewController {
    
    public override var titleMode: StepViewControllerTitleMode { .customOrNone }
    
    //MARK: Private properties
    private var barcodeStep: MWBarcodeStep { self.mwStep as! MWBarcodeStep }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let barcodeScanner = _MWBarcodeStepViewController() { [weak self] codeFound in
            guard let self = self else { return }
            let result = BarcodeResult(identifier: self.barcodeStep.identifier, codeFound: codeFound)
            self.addStepResult(result)
            self.goForward()
        }
        self.addCovering(childViewController: barcodeScanner)
    }
}

private class _MWBarcodeStepViewController: BarcodeScannerViewController {
    
    override var instructionsText: String {
        get { L10n.Camera.barcodeLabel }
        set {  }
    }
    
    override var supportedBarcodes: [AVMetadataObject.ObjectType] {
        get { [.upce,
               .code39,
               .code39Mod43,
               .ean13,
               .ean8,
               .code93,
               .code128,
               .pdf417,
               .aztec,
               .interleaved2of5,
               .itf14,
               .dataMatrix] }
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

