//
//  MWQRCodeResult.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 3/12/20.
//

import Foundation
import MobileWorkflowCore

fileprivate let kQRCode = "kQRCode"

final class MWQRCodeResult: ORKResult, Codable {
    
    let qrCode: String
    
    init(identifier: String, qrCode: String) {
        self.qrCode = qrCode
        super.init(identifier: identifier)
    }
    
    override func copy() -> Any {
        return MWQRCodeResult(identifier: self.identifier, qrCode: self.qrCode)
    }
    
    required init?(coder decoder: NSCoder) {
        guard let qrCode = decoder.decodeObject(forKey: kQRCode) as? String else { return nil }
        self.qrCode = qrCode
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.qrCode, forKey: kQRCode)
        super.encode(with: coder)
    }
}

extension MWQRCodeResult: ValueProvider {
    var content: [AnyHashable : Codable] {
        return [self.identifier:[kQRCode:self.qrCode]]
    }
    
    func fetchValue(for path: String) -> Any? {
        return self.qrCode
    }
    
    func fetchProvider(for path: String) -> ValueProvider? {
        return self.qrCode
    }
}
