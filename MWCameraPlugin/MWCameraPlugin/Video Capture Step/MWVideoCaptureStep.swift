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

public class CameraVideoCaptureMetadata: StepMetadata {
    enum CodingKeys: CodingKey {
        case deviceCamera
        case audioMute
        case duration
        case torchMode
    }
    
    let deviceCamera: String
    let audioMute: Bool?
    let duration: Float?
    let torchMode: String?
    
    init(id: String, title: String, deviceCamera: String, audioMute: Bool?, duration: Float?, torchMode: String?, next: PushLinkMetadata?, links: [LinkMetadata]) {
        self.deviceCamera = deviceCamera
        self.audioMute = audioMute
        self.duration = duration
        self.torchMode = torchMode
        super.init(id: id, type: "io.mobileworkflow.VideoCapture", title: title, next: next, links: links)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.deviceCamera = try container.decode(String.self, forKey: .deviceCamera)
        self.audioMute = try container.decodeIfPresent(Bool.self, forKey: .audioMute)
        self.duration = try container.decodeIfPresent(Float.self, forKey: .duration)
        self.torchMode = try container.decodeIfPresent(String.self, forKey: .torchMode)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.deviceCamera, forKey: .deviceCamera)
        try container.encodeIfPresent(self.audioMute, forKey: .audioMute)
        try container.encodeIfPresent(self.duration, forKey: .duration)
        try container.encodeIfPresent(self.torchMode, forKey: .torchMode)
        try super.encode(to: encoder)
    }
}


