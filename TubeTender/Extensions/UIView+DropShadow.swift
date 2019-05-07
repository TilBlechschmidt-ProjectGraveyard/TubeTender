//
//  UIView+DropShadow.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 07.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

extension UIView {
    func addDropShadow() {
        let shadowPath = UIBezierPath(rect: bounds.insetBy(dx: -5, dy: -5))
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.5
        layer.shadowPath = shadowPath.cgPath
    }

    func updateDropShadow() {
        addDropShadow()
    }
}
