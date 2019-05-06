//
//  NavigationController+Orientation.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 04.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

extension UINavigationController {
    override open var shouldAutorotate: Bool {
        return true
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return visibleViewController?.supportedInterfaceOrientations ?? .all
    }
}
