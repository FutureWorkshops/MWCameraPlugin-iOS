//
//  MWImageCaptureViewController.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 07/12/2021.
//

import UIKit
import MobileWorkflowCore
import AVFoundation
import Combine

final class MWImageCaptureViewController: MWContentStepViewController, UINavigationControllerDelegate {

    private lazy var imageCaptureView : MWImageCaptureView = {
        let imageCaptureView = MWImageCaptureView(imageCaptureStep: self.imageCaptureStep, frame: .zero)
        imageCaptureView.delegate = self
        imageCaptureView.translatesAutoresizingMaskIntoConstraints = false
        return imageCaptureView
    }()
    
    private lazy var sessionQueue = DispatchQueue(label: "session queue")
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var templateImageLoad: AnyCancellable?
    private var capturedImageData: Data? {
        didSet{

            self.imageCaptureView.capturedImage = self.capturedImageData != nil ? self.previewImage : nil
            
            // Remove the old file, if it exists, now that new data was acquired or reset
            if let fileURL = self.fileURL {
                try? FileManager.default.removeItem(at: fileURL)
                self.fileURL = nil
            }
            
            self.addResult()
        
        }
    }
    private var compressedImageData: Data?
    private var rawImageData: Data?
    private var fileURL: URL? {
        didSet {
            self.configureNavigationFooter()
        }
    }
    private var previewImage: UIImage?
    
    private var captureRaw: Bool {
        return self.imageCaptureStep.captureRaw
    }
    
    private var imageDataExtension: String = "jpg"
    
    private lazy var imagePickerController: UIImagePickerController = {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        return imagePickerController
    }()
    
    private var imageCaptureStep: MWImageCaptureStep {
        return self.mwStep as! MWImageCaptureStep
    }
    
    override init(step: Step) {
        super.init(step: step)
        
        self.view.addSubview(self.imageCaptureView)
        
        if self.imageCaptureView.imageCaptureStep.showGalleryOption {
            let iconImage = UIImage(systemName: "photo.on.rectangle")
            self.utilityButtonItem = UIBarButtonItem(image: iconImage, style: .plain, target: self, action: #selector(self.imagePickerPressed))
        }
        
        self.setUpConstraints()
        
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureNavigationFooter()

        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted == false {
                    self?.handle(error: ImageCaptureError.captureErrorNoPermission)
                }
            }
        }
        
        self.sessionQueue.async {
            self.queue_SetupCaptureSession()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.sessionQueue.async {
            self.captureSession?.startRunning()
        }
        
        self.loadTemplateImage()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if self.captureSession?.isRunning == true {
            self.sessionQueue.async {
                self.captureSession?.stopRunning()
            }
        }
        
        self.templateImageLoad?.cancel()
        
        super.viewWillDisappear(animated)
    }
    
    override func updateBarButtonItems() {
        self.navigationItem.rightBarButtonItems = [self.cancelButtonItem, self.utilityButtonItem].compactMap {$0}
    }
    
    private func configureNavigationFooter() {
        
        let skipButton = self.imageCaptureStep.isOptional ? ButtonConfig(isEnabled: true,
                                                                         style: .textOnly,
                                                                         title: L10n.ImageCaptureStep.skipButtonTitle,
                                                                         action: self.goForward) : nil
        
        if self.fileURL != nil {
            
            self.navigationFooterConfig = NavigationFooterView.Config(
                primaryButton: ButtonConfig(isEnabled: true, style: .primary, title: L10n.ImageCaptureStep.nextButtonTitle, action: self.goForward),
                secondaryButton: ButtonConfig(isEnabled: true, style: .textOnly, title: L10n.ImageCaptureStep.recaptureImage, action: self.recaptureImage),
                hasBlurredBackground: false
            )
        
        } else {

            self.navigationFooterConfig = NavigationFooterView.Config(
                primaryButton: ButtonConfig(isEnabled: self.imageCaptureView.error == nil, style: .primary, title: L10n.ImageCaptureStep.captureImage, action: self.captureImage),
                secondaryButton: skipButton,
                hasBlurredBackground: false
            )
        }
        
        self.updateNavigationFooterView()
        
    }
    
    private func setUpConstraints(){
        
        NSLayoutConstraint.activate([NSLayoutConstraint(item: imageCaptureView,
                                                        attribute: .top,
                                                        relatedBy: .equal,
                                                        toItem: self.contentView,
                                                        attribute: .top,
                                                        multiplier: 1.0,
                                                        constant: 0),
                                     NSLayoutConstraint(item: imageCaptureView,
                                                        attribute: .left,
                                                        relatedBy: .equal,
                                                        toItem: self.contentView,
                                                        attribute: .left,
                                                        multiplier: 1.0,
                                                        constant: 0),
                                     NSLayoutConstraint(item: imageCaptureView,
                                                        attribute: .right,
                                                        relatedBy: .equal,
                                                        toItem: self.contentView,
                                                        attribute: .right,
                                                        multiplier: 1.0,
                                                        constant: 0),
                                     NSLayoutConstraint(item: imageCaptureView,
                                                        attribute: .bottom,
                                                        relatedBy: .equal,
                                                        toItem: self.contentView,
                                                        attribute: .bottom,
                                                        multiplier: 1.0,
                                                        constant: 0)])

    }
    
    private func loadTemplateImage(){
        
        guard let imageUrl = self.imageCaptureStep.imageURL, self.imageCaptureView.templateImage == nil else {return}
        
        self.templateImageLoad = self.imageCaptureStep.services.imageLoadingService.asyncLoad(image: imageUrl, session: self.imageCaptureStep.session) { [weak self] in
            self?.imageCaptureView.templateImage = $0
            self?.templateImageLoad = nil
        }
        
    }
    
    private var imageFormat: [String : Any] {
        let compression = [AVVideoQualityKey:self.imageCaptureView.imageCaptureStep.compressionQuality]
        return [AVVideoCodecKey: AVVideoCodecType.jpeg,
                AVVideoCompressionPropertiesKey: compression]
    }
    
    private func createRawPhotoSettings(_ rawPixelFormatType: OSType) -> AVCapturePhotoSettings {

        let photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawPixelFormatType, processedFormat: self.imageFormat)

        photoSettings.flashMode = self.photoOutput?.supportedFlashModes.contains(.on) ?? false ? .auto : .off
    
        return photoSettings
        
    }
    
    private var generatePhotoSetting: AVCapturePhotoSettings {

        let photoSettings = AVCapturePhotoSettings(format: self.imageFormat)

        photoSettings.flashMode = self.photoOutput?.supportedFlashModes.contains(.on) ?? false ? .auto : .off
    
        return photoSettings
        
    }
    
    private func queue_SetupCaptureSession(){
        
        // Create the session
        self.captureSession = AVCaptureSession()
        
        guard let captureSession = self.captureSession else { return }

        captureSession.beginConfiguration()
        captureSession.automaticallyConfiguresCaptureDeviceForWideColor = false
        captureSession.sessionPreset = .photo
        
        // Get the camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.imageCaptureStep.devicePosition) {
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                let photoOutput = AVCapturePhotoOutput()
                if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                    captureSession.addInput(input)
                    captureSession.addOutput(photoOutput)
                    self.photoOutput = photoOutput
            
                }else{
                    DispatchQueue.main.async {
                        self.handle(error: ImageCaptureError.captureErrorNoPermission)
                    }
                    self.captureSession = nil
                }
            }catch {
                DispatchQueue.main.async {
                    self.handle(error: error)
                }
                self.captureSession = nil
            }
            
        }else{
            DispatchQueue.main.async {
                self.handle(error: ImageCaptureError.captureErrorCameraNotFound)
            }
            self.captureSession = nil
        }
        
        captureSession.commitConfiguration()
        self.imageCaptureView.session = captureSession
        
    }
    
    private func handle(error: Error) {
        
        // Shut down the session, if running
        if self.captureSession?.isRunning == true {
            self.sessionQueue.async {
                self.captureSession?.stopRunning()
            }
        }
        
        // Reset the state to before the capture session was setup.  Order here is important
        self.captureSession = nil
        self.photoOutput = nil
        self.imageCaptureView.session = nil
        self.imageCaptureView.capturedImage = nil
        self.capturedImageData = nil
        self.fileURL = nil
        
        // Show the error in the image capture view
        self.imageCaptureView.error = error
        
        self.show(error)
    }
    
    private func writeCapturedDataWithError() throws -> URL? {
        
        guard let outputDirectory = self.outputDirectory else {
            throw ImageCaptureError.noOutputDirectory
        }
        
        let url = outputDirectory.appendingPathComponent(self.mwStep.identifier).appendingPathExtension(self.imageDataExtension)
            
        // If set properly, the outputDirectory is already created, so write the file into it
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(atPath: url.path)
            } catch {
                throw ImageCaptureError.cannotWriteFile
            }
        }
    

        let created = fileManager.createFile(atPath: url.path, contents: self.capturedImageData, attributes: [FileAttributeKey.protectionKey : FileProtectionType.completeUnlessOpen])
        if created == false {
            throw ImageCaptureError.cannotWriteFile
        }
    
        return url
    }
    
    func addResult(){
        
        if self.fileURL == nil && self.capturedImageData != nil {
            
            do {
                self.fileURL = try self.writeCapturedDataWithError()
            }catch {
                self.handle(error: error)
            }
            
        }
        
        if let fileURL = self.fileURL {
            let fileResult = FileResult(identifier: self.mwStep.identifier,
                                        fileIdentifier: self.imageDataExtension,
                                        fileURL: fileURL,
                                        contentType: BinaryContentType.Image.jpeg)
            self.addStepResult(fileResult)
        }
        
    }
    
    func captureImage(){
        self.imageCaptureView.capturePressed()
    }
    
    func recaptureImage(){
        self.imageCaptureView.retakePressed()
    }
    
    @IBAction func imagePickerPressed() {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            self.present(self.imagePickerController, animated: true, completion: nil)
        }else{
            self.handle(error: ImageCaptureError.photoLibraryNotAvailable)
        }
        
    }


}

extension MWImageCaptureViewController: MWImageCaptureViewDelegate {
    
    func capturePressed(handler: ((Bool) -> Void)?) {
        
        self.sessionQueue.async {
            if self.captureRaw, let rawPixelFormatType = self.photoOutput?.availableRawPhotoFileTypes.first as? OSType {
                self.photoOutput?.capturePhoto(with: self.createRawPhotoSettings(rawPixelFormatType), delegate: self)
            }else{
                self.photoOutput?.capturePhoto(with: self.generatePhotoSetting, delegate: self)
            }
            
            DispatchQueue.main.async {
                handler?(self.capturedImageData != nil)
            }
        }
        
    }
    
    func retakePressed(handler: (() -> Void)?) {
        // Start the capture session, and reset the captured image to nil
        
        self.sessionQueue.async {
            self.captureSession?.startRunning()
            
            DispatchQueue.main.async {
                self.capturedImageData = nil
                handler?()
            }
        }
    }
    
    func videoOrientationDidChange(videoOrientation: AVCaptureVideoOrientation) {
        
        self.photoOutput?.connections.first?.videoOrientation = videoOrientation
        
    }
    
}

extension MWImageCaptureViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let data = photo.fileDataRepresentation() else {return}
        
        if self.captureRaw {
            if photo.isRawPhoto {
                self.rawImageData = data
            } else {
                self.previewImage = UIImage(data: data)
            }
        } else {
            self.compressedImageData = data
            self.previewImage = UIImage(data: data)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
        if self.capturedImageData != nil {
            self.captureSession?.stopRunning()
        }
        
        DispatchQueue.main.async {
            if self.captureRaw {
                self.capturedImageData = self.rawImageData
            }else{
                self.capturedImageData = self.compressedImageData
            }
        }
    
    }
}

extension MWImageCaptureViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.sessionQueue.async {
            self.captureSession?.stopRunning()
            
            DispatchQueue.main.async {
                guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {return}
                self.previewImage = image
                let imageData = image.jpegData(compressionQuality: 1.0)
                self.capturedImageData = imageData
                
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
}

extension BinaryContentType {
    
    //getExtension is internal
    fileprivate static func getExtension(type: String) -> String? {
        return type.components(separatedBy: "/").last
    }
    
}
