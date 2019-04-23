//
//  AppDelegate.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 10.10.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import AVKit
import GoogleSignIn
import UIKit
import YoutubeKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let hlsServer = try? HLSServer(port: Constants.hlsServerPort)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, options: [])
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }

        // Override point for customization after application launch.
        YoutubeKit.shared.setAPIKey("AIzaSyDEN6U1W9vvrV5CDgRizZRfd6nHnZZDydU")

        // Initialize sign-in
        GIDSignIn.sharedInstance().clientID = "1075139575942-l15imga5cglnbvjeir5aoclf9jkf07cf.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self

        var scopes = GIDSignIn.sharedInstance()?.scopes
        scopes?.append("https://www.googleapis.com/auth/youtube")
        GIDSignIn.sharedInstance()?.scopes = scopes

        GIDSignIn.sharedInstance()?.signInSilently()

        //swiftlint:disable:next force_cast
        let splitViewController = window!.rootViewController as! UISplitViewController
        splitViewController.delegate = self

        splitViewController.view.addInteraction(UIDropInteraction(delegate: IncomingVideoReceiver.default))

        NotificationCenter.default.addObserver(IncomingVideoReceiver.default,
                                               selector: #selector(IncomingVideoReceiver.default.scanPasteboardForURL),
                                               name: UIPasteboard.changedNotification,
                                               object: nil)

        UIVisualEffectView.appearance().effect = UIBlurEffect(style: .dark)

        let versionString = "\(Bundle.main.releaseVersionNumber ?? "0") (\(Bundle.main.buildVersionNumber ?? "0"))"
        Settings.set(setting: .appVersion, versionString)

        do {
            Network.reachability = try Reachability(hostname: "www.youtube.com")
            do {
                try Network.reachability?.start()
            } catch let error as Network.Error {
                print(error)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }

        NotificationCenter.default.reactive.notifications(forName: .flagsChanged).signal.take(duringLifetimeOf: self).observeValues { _ in
            guard let status = Network.reachability?.status else { return }
            print("\n\n\nReachability Summary")
            print("Status:", status)
            print("HostName:", Network.reachability?.hostname ?? "nil")
            print("Reachable:", Network.reachability?.isReachable ?? "nil")
            print("Wifi:", Network.reachability?.isReachableViaWiFi ?? "nil")
            print("Cellular:", Network.reachability?.isWWAN ?? "nil")
        }

        hlsServer?.listen()

        return true
    }

    func application(_ app: UIApplication, handleOpen url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url as URL?,
                                                 sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        IncomingVideoReceiver.default.scanPasteboardForURL()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if Settings.get(setting: .backgroundPictureInPicture) as? Bool ?? false && VideoPlayer.shared.status.value == .playing {
            VideoPlayer.shared.startPictureInPicture()
        } else if !(Settings.get(setting: .backgroundPlayback) as? Bool ?? true) {
            VideoPlayer.shared.pause()
        }
    }
}

extension AppDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

extension AppDelegate: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("\(error.localizedDescription)")
        } else {
            //            // Perform any operations on signed in user here.
            //            let userId = user.userID                  // For client-side use only!
            //            let idToken = user.authentication.idToken // Safe to send to the server
            //            let fullName = user.profile.name
            //            let givenName = user.profile.givenName
            //            let familyName = user.profile.familyName
            //            let email = user.profile.email
            //            // ...
            //            print(fullName, email)
            print("logged in")

            if let accessToken = user.authentication.accessToken {
                YoutubeKit.shared.setAccessToken(accessToken)

                NotificationCenter.default.post(name: NSNotification.Name("AppDelegate.authentication.loggedIn"),
                                                object: nil,
                                                userInfo: nil)
            }
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        print("logged out")
    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
