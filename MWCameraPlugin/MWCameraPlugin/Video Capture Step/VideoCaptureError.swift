//
//  VideoCaptureError.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 13/10/2021.
//

import Foundation

enum VideoCaptureError: LocalizedError {
    case captureErrorCameraNotFound
    case captureErrorNoPermission
    case cameraUnavailable
    
    var errorDescription: String? {
        switch self {
        case .captureErrorCameraNotFound:
            return L10n.VideoCaptureStep.captureErrorCameraNotFound
        case .captureErrorNoPermission:
            return L10n.VideoCaptureStep.captureErrorNoPermission
        case .cameraUnavailable:
            return L10n.VideoCaptureStep.cameraUnavailable
        }
    }
    
    var localizedDescription: String {
        return self.errorDescription ?? ""
    }
}
