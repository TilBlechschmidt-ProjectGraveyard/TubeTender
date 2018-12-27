//
//  SplitViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 14.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        view.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
    }
}
