//
//  SignInViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import GoogleSignIn
import UIKit

class SignInViewController: UIViewController, GIDSignInUIDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance().uiDelegate = self

        // TODO Show only one of the two depending on whether or not the user is logged in
        // Actually - if the user is not logged in don't let him do anything.
        // Show a nice welcome screen prompting to log in!
        let loginButton = UIButton()
        loginButton.setTitle("API Login", for: .normal)
        loginButton.addTarget(self, action: #selector(onLoginTap), for: .touchUpInside)

        let logoutButton = UIButton()
        logoutButton.setTitle("API Logout", for: .normal)
        logoutButton.addTarget(self, action: #selector(onLogoutTap), for: .touchUpInside)

        let webLoginButton = UIButton()
        webLoginButton.setTitle("Web Login", for: .normal)
        webLoginButton.addTarget(self, action: #selector(onWebLoginTap), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [webLoginButton, loginButton, logoutButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        view.addConstraints([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func onWebLoginTap() {
        self.showDetailViewController(WebSignInViewController(), sender: self)
    }

    @objc func onLoginTap() {
        GIDSignIn.sharedInstance().signIn()
    }

    @objc func onLogoutTap() {
        GIDSignIn.sharedInstance().disconnect()
    }
}
