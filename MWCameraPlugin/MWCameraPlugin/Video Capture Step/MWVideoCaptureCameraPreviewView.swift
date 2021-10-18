//
//  MWVideoCaptureCameraPreviewView.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 24/09/2021.
//

import UIKit
import AVFoundation
import AVKit

final class MWVideoCaptureCameraPreviewView : UIView {
    
    var videoFileURL: URL? {
        didSet{
            self.previewLayer.isHidden = self.videoFileURL != nil
        }
    }
    
    var session: AVCaptureSession? {
        get{
            return self.previewLayer.session
        }
        set{
            self.previewLayer.session = newValue
        }
    }
    
    var videoOrientation: AVCaptureVideoOrientation? {
        get {
            return self.previewLayer.connection?.videoOrientation
        }
        set {
            if let videoOrientation = newValue {
                self.previewLayer.connection?.videoOrientation = videoOrientation
            }
        }
    }
    
    private let previewLayer: AVCaptureVideoPreviewLayer
    
    override init(frame: CGRect) {
        
        self.previewLayer = AVCaptureVideoPreviewLayer()
        self.previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer.needsDisplayOnBoundsChange = true
        
        super.init(frame: frame)
        
        self.layer.addSublayer(self.previewLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        self.previewLayer.frame = self.frame
        
        self.updateInsets()
    }
    
    private func updateInsets(){
        let previewLayerContentFrameInsets = self.getPreviewLayerContentFrameInsets()
        if previewLayerContentFrameInsets != self.layoutMargins {
            self.layoutMargins = previewLayerContentFrameInsets
        }
    }
    
    private func getPreviewLayerContentFrameInsets() -> UIEdgeInsets {
        // Determine the insets on the preview layer frame that correspond to the actual video content
        // when using a videoGravity of AVLayerVideoGravityResizeAspect;
        
        guard let input = self.previewLayer.session?.inputs.first as? AVCaptureDeviceInput else {return .zero}
        
        let cmd = CMVideoFormatDescriptionGetDimensions(input.device.activeFormat.formatDescription)
        let avcvo = self.previewLayer.connection?.videoOrientation
        let landscape = avcvo == .landscapeLeft || avcvo == .landscapeRight
        let size = CGSize(width: Int(landscape ? cmd.width : cmd.height), height: Int(landscape ? cmd.height : cmd.width))
        let contentFrame = AVMakeRect(aspectRatio: size, insideRect: self.previewLayer.frame)
        let overallFrame = self.previewLayer.frame;
        
        return UIEdgeInsets(top: contentFrame.origin.y - overallFrame.origin.y,
                            left: contentFrame.origin.x - overallFrame.origin.x,
                            bottom: (overallFrame.origin.y + overallFrame.size.height) - (contentFrame.origin.y + contentFrame.size.height),
                            right: (overallFrame.origin.x + overallFrame.size.width) - (contentFrame.origin.x + contentFrame.size.width));
    }
    
}


