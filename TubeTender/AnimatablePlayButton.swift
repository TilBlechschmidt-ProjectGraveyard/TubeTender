//
//  AnimatablePlayButton.swift
//  AnimatablePlayButton
//
//  Created by suzuki keishi on 2015/12/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit

class PlayButton: UIButton {
    fileprivate var left: CAShapeLayer = CAShapeLayer()
    fileprivate var right: CAShapeLayer = CAShapeLayer()

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
        isSelected = true
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

    open func select(animate: Bool = true) {
        guard !isSelected else {
            return
        }

        isSelected = true

        left.removeAllAnimations()
        right.removeAllAnimations()

        setAnimationDuration(animate: animate)

        CATransaction.begin()
        left.add(leftBarToTriangleAnimation, forKey: "path")
        right.add(rightBarToTriangleAnimation, forKey: "path")
        CATransaction.commit()
    }

    open func deselect(animate: Bool = true) {
        guard isSelected else {
            return
        }

        isSelected = false

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

open class AnimatablePlayButton: UIButton {

    open var color: UIColor! = .white {
        didSet {
            pauseLeft.strokeColor = color.cgColor
            pauseLeftMover.strokeColor = color.cgColor
            pauseRight.strokeColor = color.cgColor
            pauseRightMover.strokeColor = color.cgColor
        }
    }
    open var bgColor: UIColor! = .black {
        didSet {
            backgroundColor = bgColor
            playTop.strokeColor = bgColor.cgColor
            playBottom.strokeColor = bgColor.cgColor
        }
    }

    fileprivate let pauseLeftSelectAnimation = CAKeyframeAnimation(keyPath: "transform")
    fileprivate let pauseRightSelectAnimation = CAKeyframeAnimation(keyPath: "transform")
    fileprivate let playTopSelectAnimation = CAKeyframeAnimation(keyPath: "transform")
    fileprivate let playBottomSelectAnimation = CAKeyframeAnimation(keyPath: "transform")
    fileprivate let pauseLeftDeSelectAnimation = CAKeyframeAnimation(keyPath: "transform")
    fileprivate let pauseRightDeSelectAnimation = CAKeyframeAnimation(keyPath: "transform")
    fileprivate let playTopDeSelectAnimation = CAKeyframeAnimation(keyPath: "transform")
    fileprivate let playBottomDeSelectAnimation = CAKeyframeAnimation(keyPath: "transform")

    fileprivate var pauseLeft: CAShapeLayer = CAShapeLayer()
    fileprivate var pauseLeftMover: CAShapeLayer = CAShapeLayer()
    fileprivate var pauseRight: CAShapeLayer = CAShapeLayer()
    fileprivate var pauseRightMover: CAShapeLayer = CAShapeLayer()
    fileprivate var playTop: CAShapeLayer = CAShapeLayer()
    fileprivate var playBottom: CAShapeLayer = CAShapeLayer()

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

    // MARK: - private
    fileprivate func setup(){
        clipsToBounds = true
        bgColor = .black
        color = .white
    }

    fileprivate func createLayers(_ frame: CGRect) {

        let pauseLineWidth:CGFloat = bounds.width/5
        let pauseLine:CGFloat = pauseLineWidth * 2
        let pausePadding:CGFloat = (bounds.height/5)
        let pauseHeight = bounds.height-(pausePadding*2)

        let pausePath: CGPath = {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: pauseHeight))
            return path
        }()

        pauseLeft.path = pausePath
        pauseLeftMover.path = pausePath
        pauseRight.path = pausePath
        pauseRightMover.path = pausePath

        print(CGPoint(x: bounds.width, y: bounds.height / 2))

        playTop.path =  {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: bounds.width, y: bounds.height / 2))
            return path
        }()

        playBottom.path = {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: bounds.height))
            path.addLine(to: CGPoint(x: bounds.width, y: bounds.height / 2))
            return path
        }()


        pauseLeft.frame = CGRect(x: (bounds.width/5)*1, y: pausePadding, width: pauseLine, height: pauseHeight)
        pauseLeft.lineWidth = pauseLine
        pauseLeft.masksToBounds = true
        layer.addSublayer(pauseLeft)

        pauseLeftMover.frame = CGRect(x: (bounds.width/5)*1, y: pausePadding, width: pauseLine * 1.25, height: pauseHeight)
        pauseLeftMover.lineWidth = pauseLine * 1.25
        pauseLeftMover.masksToBounds = true
        layer.addSublayer(pauseLeftMover)

        pauseRight.frame = CGRect(x: (bounds.width/5)*3, y: pausePadding, width: pauseLine, height: pauseHeight)
        pauseRight.lineWidth = pauseLine
        pauseRight.masksToBounds = true
        layer.addSublayer(pauseRight)

        pauseRightMover.frame = CGRect(x: (bounds.width/5)*3, y: pausePadding, width: pauseLine * 1.25, height: pauseHeight)
        pauseRightMover.lineWidth = pauseLine * 1.25
        pauseRightMover.masksToBounds = true
        layer.addSublayer(pauseRightMover)

        playTop.frame = CGRect(x: 0, y: -bounds.height, width: bounds.width-1, height: bounds.height)
        playTop.lineWidth = pauseLineWidth * 3
        playTop.masksToBounds = true
        layer.addSublayer(playTop)

        playBottom.frame = CGRect(x: 0, y: bounds.height, width: bounds.width-1, height: bounds.height)
        playBottom.lineWidth = pauseLineWidth * 3
        playBottom.masksToBounds = true
        layer.addSublayer(playBottom)

        // SELECT
        pauseLeftSelectAnimation.values = [
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.51, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.51, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.51, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.51, 0, 0)),
        ]
        pauseRightSelectAnimation.values = [
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.51, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.51, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.51, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.51, 0, 0)),
        ]
        playTopSelectAnimation.values = [
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.3, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.76, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.76, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.76, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.76, 0)),
        ]
        playBottomSelectAnimation.values = [
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.3, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.76, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.76, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.76, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.76, 0)),
        ]

        // DESELECT
        pauseLeftDeSelectAnimation.values = [
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.5, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.2, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.1, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.0, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(pauseLineWidth * 0.0, 0, 0)),
        ]
        pauseRightDeSelectAnimation.values = [
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.5, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.2, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.1, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.0, 0, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(-pauseLineWidth * 0.0, 0, 0)),
        ]
        playTopDeSelectAnimation.values = [
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.76, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.4, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.3, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, bounds.height * 0.2, 0)),
            NSValue(caTransform3D: CATransform3DIdentity),
        ]
        playBottomDeSelectAnimation.values = [
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.76, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.4, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.3, 0)),
            NSValue(caTransform3D: CATransform3DMakeTranslation(0, -bounds.height * 0.2, 0)),
            NSValue(caTransform3D: CATransform3DIdentity),
        ]

        setPauseProperty(pauseLeftSelectAnimation)
        setPauseProperty(pauseRightSelectAnimation)
        setCommonProperty(playTopSelectAnimation)
        setCommonProperty(playBottomSelectAnimation)
    }

    fileprivate func setPauseProperty(_ animation: CAKeyframeAnimation) {
        //animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
    }

    fileprivate func setCommonProperty(_ animation: CAKeyframeAnimation) {
        //animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
    }

    // MARK: - public
    open func select(animate:Bool = true) {
        isSelected = true


        pauseLeftMover.removeAllAnimations()
        pauseRightMover.removeAllAnimations()
        playTop.removeAllAnimations()
        playBottom.removeAllAnimations()

        setAnimationDurations(isAnimated: animate)
        CATransaction.begin()

        pauseLeftMover.add(pauseLeftSelectAnimation, forKey: "transform")
        pauseRightMover.add(pauseRightSelectAnimation, forKey: "transform")
        playTop.add(playTopSelectAnimation, forKey: "transform")
        playBottom.add(playBottomSelectAnimation, forKey: "transform")

        CATransaction.setAnimationDuration(animate ? 0.4 : 0.01)

        CATransaction.commit()
    }

    open func deselect(animate:Bool = true) {
        isSelected = false

        pauseLeftMover.removeAllAnimations()
        pauseRightMover.removeAllAnimations()
        playTop.removeAllAnimations()
        playBottom.removeAllAnimations()

        setAnimationDurations(isAnimated: animate)

        CATransaction.begin()
        pauseLeftMover.add(pauseLeftDeSelectAnimation, forKey: "transform")
        pauseRightMover.add(pauseRightDeSelectAnimation, forKey: "transform")
        playTop.add(playTopDeSelectAnimation, forKey: "transform")
        playBottom.add(playBottomDeSelectAnimation, forKey: "transform")

        CATransaction.setAnimationDuration(animate ? 0.4 : 0.01)


        CATransaction.commit()
    }


    private func setAnimationDurations(isAnimated: Bool){
        let animations = [pauseLeftSelectAnimation,pauseRightSelectAnimation,playTopSelectAnimation,playBottomSelectAnimation,pauseLeftDeSelectAnimation,pauseRightDeSelectAnimation,playTopDeSelectAnimation,playBottomDeSelectAnimation]

        for animation in animations{
            if isAnimated{
                animation.duration = 0.4
            }else{
                animation.duration = 0.01
            }
        }
    }

}
