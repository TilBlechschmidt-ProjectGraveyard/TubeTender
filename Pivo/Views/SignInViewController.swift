//
//  SignInViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import GoogleSignIn

class SignInViewController: UIViewController, GIDSignInUIDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance().uiDelegate = self

        // Uncomment to automatically sign in the user.
        //GIDSignIn.sharedInstance().signInSilently()

        // TODO(developer) Configure the sign-in button look/feel
        // ...

        let button = GIDSignInButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        view.addConstraints([
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 100),
        ])
    }
}
