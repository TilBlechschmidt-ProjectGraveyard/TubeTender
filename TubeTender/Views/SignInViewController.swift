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

        // TODO Show only one of the two depending on whether or not the user is logged in
        // Actually - if the user is not logged in don't let him do anything.
        // Show a nice welcome screen prompting to log in!
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.addTarget(self, action: #selector(self.onLoginTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        view.addConstraints([
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        let logoutButton = UIButton()
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.addTarget(self, action: #selector(self.onLogoutTap), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        view.addConstraints([
            logoutButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func onLoginTap() {
        GIDSignIn.sharedInstance().signIn()
    }

    @objc func onLogoutTap() {
        GIDSignIn.sharedInstance().disconnect()
    }
}
