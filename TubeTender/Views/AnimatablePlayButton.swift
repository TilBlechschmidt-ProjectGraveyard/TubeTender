//
//  AnimatablePlayButton.swift
//  AnimatablePlayButton
//
//  Created by suzuki keishi on 2015/12/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit
import ReactiveSwift

class PlayButton: UIButton {
    fileprivate var left: CAShapeLayer = CAShapeLayer()
    fileprivate var right: CAShapeLayer = CAShapeLayer()

    var isPlaying: Bool = false {
        didSet {
            if oldValue != isPlaying {
                if isPlaying {
                    changeToPlaying()
                } else {
                    changeToPaused()
                }
            }
        }
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        createLayers(frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
        createLayers(frame)
    }

    override public required init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        createLayers(frame)
    }

    convenience public init(origin: CGPoint, lengthOfSize: CGFloat){
        self.init(frame: CGRect(x: origin.x, y: origin.y, width: lengthOfSize, height: lengthOfSize))
    }

    convenience public init(lengthOfSize: CGFloat){
        self.init(frame: CGRect(x: 0, y: 0, width: lengthOfSize, height: lengthOfSize))
    }

    fileprivate func setup() {
        clipsToBounds = true
    }

    fileprivate let leftAnimation = CAKeyframeAnimation(keyPath: "path")

    fileprivate let leftTriangleToBarAnimation = CABasicAnimation(keyPath: "path")
    fileprivate let leftBarToTriangleAnimation = CABasicAnimation(keyPath: "path")
    fileprivate let rightTriangleToBarAnimation = CABasicAnimation(keyPath: "path")
    fileprivate let rightBarToTriangleAnimation = CABasicAnimation(keyPath: "path")

    fileprivate func createLayers(_ frame: CGRect) {

        let triangleSideLength = sqrt(pow(bounds.width, 2) + pow(bounds.height / 2, 2))

        let halfTriangleTop = round(sqrt(
            pow(triangleSideLength / 2, 2) - pow(bounds.height / 2, 2)
        ))

        let topCenterPoint = CGPoint(x: round(bounds.width / 2), y: halfTriangleTop)
        let bottomCenterPoint = CGPoint(x: round(bounds.width / 2), y: bounds.height - halfTriangleTop)

        let leftTrianglePath: CGPath = {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLines(between: [
                topCenterPoint,
                bottomCenterPoint,
                CGPoint(x: 0, y: bounds.height),
                CGPoint(x: 0, y: 0)
            ])
            return path
        }()

        let rightTrianglePath: CGPath = {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: bounds.width, y: bounds.height / 2))
            path.addLines(between: [
                topCenterPoint,
                bottomCenterPoint,
                CGPoint(x: bounds.width, y: bounds.height / 2),
                CGPoint(x: bounds.width, y: bounds.height / 2)
            ])
            return path
        }()

        let leftBarPath: CGPath = {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLines(between: [
                CGPoint(x: bounds.width / 3, y: 0),
                CGPoint(x: bounds.width / 3, y: bounds.height),
                CGPoint(x: 0, y: bounds.height),
                CGPoint(x: 0, y: 0)
            ])
            return path
        }()

        let rightBarPath: CGPath = {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: bounds.width, y: 0))
            path.addLines(between: [
                CGPoint(x: bounds.width / 3 * 2, y: 0),
                CGPoint(x: bounds.width / 3 * 2, y: bounds.height),
                CGPoint(x: bounds.width, y: bounds.height),
                CGPoint(x: bounds.width, y: 0)
            ])
            return path
        }()

        left.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width)
        left.lineWidth = 1
        left.path = leftTrianglePath
        left.masksToBounds = true
        left.fillColor = UIColor.white.cgColor
        layer.addSublayer(left)

        right.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width)
        right.lineWidth = 1
        right.path = rightTrianglePath
        right.masksToBounds = true
        right.fillColor = UIColor.white.cgColor
        layer.addSublayer(right)

        leftTriangleToBarAnimation.fromValue = leftTrianglePath
        leftTriangleToBarAnimation.toValue = leftBarPath
        setCommonProperty(leftTriangleToBarAnimation)

        leftBarToTriangleAnimation.fromValue = leftBarPath
        leftBarToTriangleAnimation.toValue = leftTrianglePath
        setCommonProperty(leftBarToTriangleAnimation)

        rightTriangleToBarAnimation.fromValue = rightTrianglePath
        rightTriangleToBarAnimation.toValue = rightBarPath
        setCommonProperty(rightTriangleToBarAnimation)

        rightBarToTriangleAnimation.fromValue = rightBarPath
        rightBarToTriangleAnimation.toValue = rightTrianglePath
        setCommonProperty(rightBarToTriangleAnimation)
    }

    fileprivate func setCommonProperty(_ animation: CABasicAnimation) {
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
    }

    private func changeToPaused(animate: Bool = true) {
        left.removeAllAnimations()
        right.removeAllAnimations()

        setAnimationDuration(animate: animate)

        CATransaction.begin()
        left.add(leftBarToTriangleAnimation, forKey: "path")
        right.add(rightBarToTriangleAnimation, forKey: "path")
        CATransaction.commit()
    }

    private func changeToPlaying(animate: Bool = true) {
        left.removeAllAnimations()
        right.removeAllAnimations()

        setAnimationDuration(animate: animate)

        CATransaction.begin()
        left.add(leftTriangleToBarAnimation, forKey: "path")
        right.add(rightTriangleToBarAnimation, forKey: "path")
        CATransaction.commit()
    }

    fileprivate func setAnimationDuration(animate: Bool) {
        [
            leftBarToTriangleAnimation,
            rightBarToTriangleAnimation,
            leftTriangleToBarAnimation,
            rightTriangleToBarAnimation
        ].forEach { $0.duration = animate ? 0.4 : 0.01 }
    }
}

extension Reactive where Base: PlayButton {
    var isPlaying: BindingTarget<Bool> {
        return makeBindingTarget { playButton, isPlaying in
            playButton.isPlaying = isPlaying
        }
    }
}
