//
//  MWQRCodeResult.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 3/12/20.
//

import Foundation
import MobileWorkflowCore

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
        guard let qrCode = decoder.decodeObject() as? String else { return nil }
        self.qrCode = qrCode
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.qrCode)
        super.encode(with: coder)
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.singleValueContainer()
        self.qrCode = try container.decode(String.self)
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.qrCode)
    }
}

extension MWQRCodeResult: ValueProvider {
    var content: [AnyHashable : Codable] {
        return [self.identifier: self.qrCode]
    }
    
    func fetchValue(for path: String) -> Any? {
        return self.qrCode
    }
    
    func fetchProvider(for path: String) -> ValueProvider? {
        return self.qrCode
    }
}

extension MWQRCodeResult: JSONRepresentable {
    var jsonContent: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
