//
//  MWRecordButton.swift
//  MobileWorkflowCore
//
//  Created by Julien Hebert on 08/10/2021.
//

import UIKit

final class RecordButton : UIButton {
    
    var isRecording: Bool = false {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    var strokeColor: UIColor = .white {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var lineWidth: CGFloat = 3.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var spacingRatio: CGFloat = 0.1 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var rectangleCornerRadius: CGFloat = 8.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()!
        
        self.drawStrokeCircle(context: context, rect: rect)
        
        self.drawFillCircleOrRectangle(context: context, rect: rect)
        
    }
    
    private func drawStrokeCircle(context: CGContext, rect: CGRect){
        
        context.setStrokeColor(self.strokeColor.cgColor)
        context.setLineWidth(self.lineWidth)

        let rectangle = CGRect(origin: CGPoint(x: self.lineWidth/2, y: self.lineWidth/2),
                               size: CGSize(width: rect.width - self.lineWidth, height: rect.height - self.lineWidth))
        context.addEllipse(in: rectangle)
        context.drawPath(using: .stroke)
    }
    
    private func drawFillCircleOrRectangle(context: CGContext, rect: CGRect){
        
        let fillColor : UIColor = self.isEnabled && !self.isHighlighted ? self.tintColor : self.tintColor.withAlphaComponent(0.3)
        
        context.setFillColor(fillColor.cgColor)
        
        if self.spacingRatio < 0 {self.spacingRatio = 0}
        if self.spacingRatio > 1 {self.spacingRatio = 1.0}
        
        let xGap = self.lineWidth + rect.width * self.spacingRatio
        let yGap = self.lineWidth + rect.height * self.spacingRatio
        
        let circleRect = CGRect(origin: CGPoint(x: xGap/2, y: yGap/2),
                                size: CGSize(width: rect.width - xGap, height: rect.height - yGap))
        
        if self.isRecording {
            let path = UIBezierPath(roundedRect: circleRect.rectInsideCircleRect, cornerRadius: self.rectangleCornerRadius)
            context.addPath(path.cgPath)
        }else{
            context.addEllipse(in: circleRect)
        }
        
        context.drawPath(using: .fill)
    }
    
}


extension CGRect {
    
    fileprivate var rectInsideCircleRect: CGRect {
        let xDiameter = self.width
        let yDiameter = self.height
        let width = (pow(xDiameter, 2)/2).squareRoot()
        let height = (pow(yDiameter, 2)/2).squareRoot()
        let xD = (xDiameter - width)/2
        let yD = (yDiameter - height)/2
        let origin = CGPoint(x: self.origin.x + xD, y: self.origin.y + yD)
        let size = CGSize(width: width, height: height)
        return CGRect(origin: origin, size: size)
    }
    
}
