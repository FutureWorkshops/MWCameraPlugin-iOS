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
    
    enum VideoCaptureStep {
        static let startRecording = L10n.localisedString(key: "videoCaptureStep.startRecording")
        static let stopRecording = L10n.localisedString(key: "videoCaptureStep.stopRecording")
        static let startAgain = L10n.localisedString(key: "videoCaptureStep.startAgain")
        static let captureErrorNoPermission = L10n.localisedString(key: "videoCaptureStep.captureErrorNoPermission")
        static let captureErrorCameraNotFound = L10n.localisedString(key: "videoCaptureStep.captureErrorCameraNotFound")
        static let captureErrorNoPermissions = L10n.localisedString(key: "videoCaptureStep.captureErrorNoPermissions")
        static let cameraUnavailable = L10n.localisedString(key: "videoCaptureStep.cameraUnavailable")
        static let rotateDevice = L10n.localisedString(key: "videoCaptureStep.rotateDevice")
        static let openCamera = L10n.localisedString(key: "videoCaptureStep.openCamera")
        
        static let cancelTitle = L10n.localisedString(key: "videoCaptureStep.cancelTitle")
        static let nextButtonTitle = L10n.localisedString(key: "videoCaptureStep.nextButtonTitle")
        static let skipButtonTitle = L10n.localisedString(key: "videoCaptureStep.skipButtonTitle")
        
    }
}
