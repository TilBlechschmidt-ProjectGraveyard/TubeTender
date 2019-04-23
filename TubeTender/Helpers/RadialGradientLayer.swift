//
//  RadialGradientLayer.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 11.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class RadialGradientLayer: CALayer {

    var center: CGPoint {
        return CGPoint(x: bounds.width/2, y: bounds.height/2)
    }

    var radius: CGFloat {
        return (bounds.width + bounds.height)/2
    }

    var colors: [UIColor] = [UIColor.black, UIColor.lightGray] {
        didSet {
            setNeedsDisplay()
        }
    }

    var cgColors: [CGColor] {
        return colors.map { (color) -> CGColor in
            return color.cgColor
        }
    }

    override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }

    override init(layer: Any) {
        super.init()
        needsDisplayOnBoundsChange = true
    }

    required init(coder aDecoder: NSCoder) {
        super.init()
    }

    override func draw(in ctx: CGContext) {
        ctx.saveGState()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 0.025, 0.06, 1.0]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: locations) else {
            return
        }
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: radius, options: CGGradientDrawingOptions(rawValue: 0))
    }

}

//class RadialGradientView: UIView {
//
//    private let gradientLayer = RadialGradientLayer()
//
//    var colors: [UIColor] {
//        get {
//            return gradientLayer.colors
//        }
//        set {
//            gradientLayer.colors = newValue
//        }
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        if gradientLayer.superlayer == nil {
//            layer.insertSublayer(gradientLayer, at: 0)
//        }
//        gradientLayer.frame = bounds
//    }
//
//}
