//
//  MWVideoCaptureStep.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 13/10/2021.
//

import Foundation
import AVFoundation
import MobileWorkflowCore

public protocol MWVideoCaptureStep: Step {
    var duration: TimeInterval { get }
    var audioMute: Bool { get }
    var torchMode: AVCaptureDevice.TorchMode { get }
    var deviceCamera: DeviceCamera { get }
    var videoOrientation: VideoOrientation { get }
}

public enum VideoOrientation : String {
    case portrait = "portrait"
    case landscape = "landscape"
    case any = "any"
}

public enum DeviceCamera : String {
    case any = "any"
    case back = "back"
    case front = "front"
}

public extension MWVideoCaptureStep {
    
    var fileName: String {
        return "\(self.identifier).mp4"
    }
    
    func fileResult(_ fileURL: URL) -> FileResult {
        let fileResult = FileResult(identifier: self.identifier,
                                    fileIdentifier: BinaryContentType.getExtension(type: BinaryContentType.Video.mp4) ?? self.identifier,
                                    fileURL: fileURL,
                                    contentType: BinaryContentType.Video.mp4)
        return fileResult
    }
    
}

extension VideoOrientation {
    
    var supportsLandscape: Bool {
        switch self {
        case .landscape, .any: return true
        case .portrait: return false
        }
    }
    
}

extension BinaryContentType {
    
    //getExtension is internal
    fileprivate static func getExtension(type: String) -> String? {
        return type.components(separatedBy: "/").last
    }
    
}

extension AVCaptureDevice.TorchMode {
    
    init(stringValue: String?){
        if let stringValue = stringValue, let rawValue = Int(stringValue), let torchMode = AVCaptureDevice.TorchMode(rawValue: rawValue) {
            self = torchMode
        }else{
            self = .off
        }
    }
    
}


