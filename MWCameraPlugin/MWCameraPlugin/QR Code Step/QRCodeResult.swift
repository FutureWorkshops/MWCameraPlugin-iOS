//
//  QRCodeResult.swift
//  MWCameraPlugin
//
//  Created by Igor Ferreira on 16/2/22.
//

import Foundation
import MobileWorkflowCore

final class QRCodeResult: StepResult, Codable {
    
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

extension QRCodeResult: ValueProvider {
    func fetchValue(for path: String) -> Any? {
        return self.codeFound
    }
    
    func fetchProvider(for path: String) -> ValueProvider? {
        return self.codeFound
    }
}

extension QRCodeResult: JSONRepresentable {
    var jsonContent: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
