//
//  BarcodeResult.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 3/12/20.
//

import Foundation
import MobileWorkflowCore

final class BarcodeResult: StepResult, Codable {
    
    var identifier: String
    let codeFound: String
    
    init(identifier: String, codeFound: String) {
        self.identifier = identifier
        self.codeFound = codeFound
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.codeFound)
    }
}

extension BarcodeResult: ValueProvider {
    func fetchValue(for path: String) -> Any? {
        return self.codeFound
    }
    
    func fetchProvider(for path: String) -> ValueProvider? {
        return self.codeFound
    }
}

extension BarcodeResult: JSONRepresentable {
    var jsonContent: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
