//
//  MWImageCaptureCameraPreviewView.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 07/12/2021.
//

import UIKit
import MobileWorkflowCore
import AVFAudio

fileprivate let PreviewImagePadding: CGFloat = 20.0

final class MWImageCaptureCameraPreviewView : UIView {
    
    var templateImageInsets : UIEdgeInsets = UIEdgeInsets(top: 0.1, left: 0.1, bottom: 0.1, right: 0.1)
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer()
    private lazy var templateImageView = UIImageView()
    private var templateImageViewTopInsetConstraint : NSLayoutConstraint!
    private var templateImageViewLeftInsetConstraint : NSLayoutConstraint!
    private var templateImageViewBottomInsetConstraint : NSLayoutConstraint!
    private var templateImageViewRightInseConstraint : NSLayoutConstraint!
    private lazy var capturedImageView = UIImageView()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer.needsDisplayOnBoundsChange = true
        self.layer.addSublayer(self.previewLayer)

        self.capturedImageView.contentMode = .scaleAspectFit
        self.addSubview(self.capturedImageView)

        self.templateImageView.contentMode = .scaleAspectFit
        self.templateImageView.isHidden = true
        self.addSubview(self.templateImageView)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.templateImageView.translatesAutoresizingMaskIntoConstraints = false
        self.capturedImageView.translatesAutoresizingMaskIntoConstraints = false
        self.setUpConstraints()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpConstraints(){
        var constraints : [NSLayoutConstraint] = []
        
        self.templateImageView.setContentHuggingPriority(UILayoutPriority(0), for: .horizontal)
        self.templateImageView.setContentHuggingPriority(UILayoutPriority(0), for: .vertical)
        self.templateImageView.setContentCompressionResistancePriority(UILayoutPriority(0), for: .horizontal)
        self.templateImageView.setContentCompressionResistancePriority(UILayoutPriority(0), for: .vertical)
        self.capturedImageView.setContentHuggingPriority(UILayoutPriority(0), for: .horizontal)
        self.capturedImageView.setContentHuggingPriority(UILayoutPriority(0), for: .vertical)
        self.capturedImageView.setContentCompressionResistancePriority(UILayoutPriority(0), for: .horizontal)
        self.capturedImageView.setContentCompressionResistancePriority(UILayoutPriority(0), for: .vertical)

        self.templateImageViewTopInsetConstraint = NSLayoutConstraint(item: self.templateImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)

        self.templateImageViewLeftInsetConstraint = NSLayoutConstraint(item: self.templateImageView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0)

        self.templateImageViewBottomInsetConstraint = NSLayoutConstraint(item: self.templateImageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)

        self.templateImageViewRightInseConstraint = NSLayoutConstraint(item: self.templateImageView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0)
        
        constraints.append(contentsOf: [self.templateImageViewTopInsetConstraint,
                                        self.templateImageViewLeftInsetConstraint,
                                        self.templateImageViewBottomInsetConstraint,
                                        self.templateImageViewRightInseConstraint])
        
        constraints.append(contentsOf: [NSLayoutConstraint(item: self.capturedImageView,
                                                           attribute: .top,
                                                           relatedBy: .equal,
                                                           toItem: self,
                                                           attribute: .top,
                                                           multiplier: 1.0,
                                                           constant: PreviewImagePadding),
                                        NSLayoutConstraint(item: self.capturedImageView,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: self,
                                                           attribute: .leading,
                                                           multiplier: 1.0,
                                                           constant: PreviewImagePadding),
                                        NSLayoutConstraint(item: self.capturedImageView,
                                                           attribute: .trailing,
                                                           relatedBy: .equal,
                                                           toItem: self,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: -PreviewImagePadding),
                                        NSLayoutConstraint(item: self.capturedImageView,
                                                           attribute: .bottom,
                                                           relatedBy: .equal,
                                                           toItem: self,
                                                           attribute: .bottom,
                                                           multiplier: 1.0,
                                                           constant: -PreviewImagePadding)])
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
    var session : AVCaptureSession? {
        get{
            return self.previewLayer.session
        }
        set {
            self.previewLayer.session = newValue
        }
    }
    
    var templateImage : UIImage? {
        get{
            return self.templateImageView.image
        }
        set {
            self.templateImageView.image = newValue?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    var isTemplateImageHidden : Bool {
        get{
            return self.templateImageView.isHidden
        }
        set {
            self.templateImageView.isHidden = newValue
        }
    }
    
    var capturedImage : UIImage? {
        get{
            return self.capturedImageView.image
        }
        set {
            self.capturedImageView.image = newValue
            self.previewLayer.isHidden = newValue != nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.previewLayer.frame = self.frame
        
        self.updateInsets()
    }
    
    private func updateInsets(){
        let previewLayerContentFrameInsets = self.getPreviewLayerContentFrameInsets()
        if (!UIEdgeInsetsEqualToEdgeInsets(previewLayerContentFrameInsets, self.layoutMargins)) {
            self.layoutMargins = previewLayerContentFrameInsets
        }
        
        // Update the insets on the template image view, if needed
        let previewLayerContentFrame = self.previewLayer.frame.inset(by: previewLayerContentFrameInsets)
        
        let insets = UIEdgeInsets(top: round(self.templateImageInsets.top * previewLayerContentFrame.size.height),
                                  left: round(self.templateImageInsets.left * previewLayerContentFrame.size.width),
                                  bottom: round(self.templateImageInsets.bottom * previewLayerContentFrame.size.height),
                                  right: round(self.templateImageInsets.right * previewLayerContentFrame.size.width))
    
        if (self.templateImageViewTopInsetConstraint.constant != insets.top) {
            self.templateImageViewTopInsetConstraint.constant = insets.top
        }
        if (self.templateImageViewLeftInsetConstraint.constant != insets.left) {
            self.templateImageViewLeftInsetConstraint.constant = insets.left
        }
        if (self.templateImageViewBottomInsetConstraint.constant != -insets.bottom) {
            self.templateImageViewBottomInsetConstraint.constant = -insets.bottom
        }
        if (self.templateImageViewRightInseConstraint.constant != -insets.right) {
            self.templateImageViewRightInseConstraint.constant = -insets.right
        }
        
    }
    
    private func getPreviewLayerContentFrameInsets() -> UIEdgeInsets {

        guard let inputs = self.previewLayer.session?.inputs, let input = inputs.first as? AVCaptureDeviceInput else {return .zero}
                
        let videoDimensions = CMVideoFormatDescriptionGetDimensions(input.device.activeFormat.formatDescription)
        let orientation = self.previewLayer.connection?.videoOrientation
        let landscape = (orientation == .landscapeLeft || orientation == .landscapeRight)
        
        let size = CGSize(width: CGFloat(landscape ? videoDimensions.width : videoDimensions.height),
                          height: CGFloat(landscape ? videoDimensions.height : videoDimensions.width))
        
        let contentFrame = AVMakeRect(aspectRatio: size, insideRect: self.previewLayer.frame)
        let overallFrame = self.previewLayer.frame
        
        return UIEdgeInsets(top: contentFrame.origin.y - overallFrame.origin.y,
                            left: contentFrame.origin.x - overallFrame.origin.x,
                            bottom: (overallFrame.origin.y + overallFrame.size.height) - (contentFrame.origin.y + contentFrame.size.height),
                            right: (overallFrame.origin.x + overallFrame.size.width) - (contentFrame.origin.x + contentFrame.size.width))
        
    }
    
    var videoOrientation : AVCaptureVideoOrientation? {
        get{
            return self.previewLayer.connection?.videoOrientation
        }
        set {
            guard let videoOrientation = newValue else {return}
            self.previewLayer.connection?.videoOrientation = videoOrientation
        }
    }
    
}

