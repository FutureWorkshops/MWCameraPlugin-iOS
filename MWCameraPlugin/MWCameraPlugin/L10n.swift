//
//  L10n.swift
//  MWCameraPlugin
//
//  Created by Xavi Moll on 14/4/21.
//

import Foundation

internal enum L10n {
    private static let LocalizationTable = "Localizable"
    private static var bundle: Bundle { Bundle(for: MWCameraQRCodeStep.self) }
    
    static func localisedString(key: String, fallback: String? = nil) -> String {
        return bundle.localizedString(forKey: key, value: fallback, table: LocalizationTable)
    }
    
    enum Camera {
        static let errorTitle = L10n.localisedString(key: "alert.error.title")
        static let errorMessage = L10n.localisedString(key: "alert.error.message")
        static let qrLabel = L10n.localisedString(key: "qr.label")
        static let barcodeLabel = L10n.localisedString(key: "barcode.label")
    }
}
