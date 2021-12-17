//
//  MWImageCaptureError.swift
//  MWCameraPlugin
//
//  Created by Julien Hebert on 14/12/2021.
//

import Foundation

enum ImageCaptureError: LocalizedError {
    case captureErrorCameraNotFound
    case captureErrorNoPermission
    case cameraUnavailable
    case noOutputDirectory
    case cannotWriteFile
    case photoLibraryNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .captureErrorCameraNotFound:
            return L10n.ImageCaptureStep.captureErrorCameraNotFound
        case .captureErrorNoPermission:
            return L10n.ImageCaptureStep.captureErrorNoPermissions
        case .cameraUnavailable:
            return L10n.ImageCaptureStep.cameraUnavailable
        case .noOutputDirectory:
            return L10n.ImageCaptureStep.captureErrorNoOutputDirectory
        case .cannotWriteFile:
            return L10n.ImageCaptureStep.captureErrorCannotWriteFile
        case .photoLibraryNotAvailable:
            return L10n.ImageCaptureStep.photoLibraryNotAvailable
        }
    }
    
    var localizedDescription: String {
        return self.errorDescription ?? ""
    }
}
