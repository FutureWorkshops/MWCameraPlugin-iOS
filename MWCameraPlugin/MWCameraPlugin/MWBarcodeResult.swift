//
//  MWBarcodeResult.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 3/12/20.
//

import Foundation
import MobileWorkflowCore

final class MWBarcodeResult: ORKResult, Codable {
    
    let codeFound: String
    
    init(identifier: String, codeFound: String) {
        self.codeFound = codeFound
        super.init(identifier: identifier)
    }
    
    override func copy() -> Any {
        return MWBarcodeResult(identifier: self.identifier, codeFound: self.codeFound)
    }
    
    required init?(coder decoder: NSCoder) {
        guard let qrCode = decoder.decodeObject() as? String else { return nil }
        self.codeFound = qrCode
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.codeFound)
        super.encode(with: coder)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.codeFound = try container.decode(String.self)
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.codeFound)
    }
}

extension MWBarcodeResult: ValueProvider {
    var content: [AnyHashable : Codable] {
        return [self.identifier: self.codeFound]
    }
    
    func fetchValue(for path: String) -> Any? {
        return self.codeFound
    }
    
    func fetchProvider(for path: String) -> ValueProvider? {
        return self.codeFound
    }
}

extension MWBarcodeResult: JSONRepresentable {
    var jsonContent: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
