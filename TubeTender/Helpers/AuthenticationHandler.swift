//
//  AuthenticationHandler.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 07.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import GoogleSignIn
import os.log
import ReactiveSwift
import YoutubeKit

private let requiredScopes: [String] = [
    "https://www.googleapis.com/auth/youtube"
]

enum AuthenticationState {
    case loggedIn(user: GIDGoogleUser)
    case loginFailed(reason: Error)
    case loggedOut
}

enum AuthenticationHandlerError: Error {
    case unableToLogin
    case noCredentialsAvailable
}

class AuthenticationHandler: NSObject {
    private let sdk: GIDSignIn

    private let state = MutableProperty<AuthenticationState>(.loggedOut)

    init(googleSignIn sdk: GIDSignIn) {
        // Initialize properties and the superclass
        self.sdk = sdk
        super.init()

        // Initialize sign-in
        sdk.clientID = "1075139575942-l15imga5cglnbvjeir5aoclf9jkf07cf.apps.googleusercontent.com"
        sdk.delegate = self

        // Extend the scopes
        var scopes = sdk.scopes
        scopes? += requiredScopes
        sdk.scopes = scopes
    }

    func awaitGoogleSDKSignIn() -> SignalProducer<GIDGoogleUser, Error> {
        let isLoggedIn = sdk.currentUser != nil
        let hasCredentialsStored = sdk.hasAuthInKeychain()

        guard isLoggedIn || hasCredentialsStored else {
            // throw
            return SignalProducer(error: AuthenticationHandlerError.noCredentialsAvailable)
        }

        switch state.value {
        case .loggedIn(let user):
            return SignalProducer(value: user)
        default:
            return state.producer
                .on(starting: {
                    DispatchQueue.main.async {
                        self.sdk.signInSilently()
                    }
                })
                .filter { state in
                    switch state {
                    case .loggedOut:
                        return false
                    default:
                        return true
                    }
                }
                .attemptMap { state in
                    switch state {
                    case .loggedIn(let user):
                        return user
                    case .loginFailed(let error):
                        throw error
                    default:
                        throw AuthenticationHandlerError.unableToLogin
                    }
                }
                .take(first: 1)
        }
    }
}

extension AuthenticationHandler: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            os_log("Failed to login: %@", log: .googleSignIn, type: .error, error.localizedDescription)
            state.value = .loginFailed(reason: error)
        } else if let user = user {
            os_log("Logged in as %@", log: .googleSignIn, type: .info, user.profile.name)

            if let accessToken = user.authentication.accessToken {
                YoutubeKit.shared.setAccessToken(accessToken)
                NotificationCenter.default.post(name: .googleSignInSucceeded, object: nil, userInfo: nil)
            }

            state.value = .loggedIn(user: user)
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error?) {
        os_log("Logged out from user %@ with error: %@", log: .googleSignIn, type: .info, user.profile.name, error?.localizedDescription ?? "nil")

        state.value = .loggedOut
    }
}
