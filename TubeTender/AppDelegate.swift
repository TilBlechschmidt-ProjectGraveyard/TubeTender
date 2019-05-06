//
//  AppDelegate.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 10.10.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import AVKit
import GoogleSignIn
import os.log
import UIKit
import YoutubeKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let commandCenter: CommandCenter
    let incomingVideoReceiver: IncomingVideoReceiver
    let videoPlayer: VideoPlayer
    let hlsServer: HLSServer?

    override init() {
        commandCenter = CommandCenter()
        videoPlayer = VideoPlayer(commandCenter: commandCenter)
        incomingVideoReceiver = IncomingVideoReceiver(videoPlayer: videoPlayer)
        hlsServer = try? HLSServer(port: Constants.hlsServerPort)
        super.init()
    }

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, options: [])
        } catch {
            os_log("Setting category to AVAudioSessionCategoryPlayback failed.", log: .audio, type: .fault)
        }

        // Override point for customization after application launch.
        YoutubeKit.shared.setAPIKey("AIzaSyDEN6U1W9vvrV5CDgRizZRfd6nHnZZDydU")

        googleSignIn()
        NotificationCenter.default.addObserver(incomingVideoReceiver,
                                               selector: #selector(incomingVideoReceiver.scanPasteboardForURL),
                                               name: UIPasteboard.changedNotification,
                                               object: nil)

        UIVisualEffectView.appearance().effect = UIBlurEffect(style: .dark)

        let versionString = "\(Bundle.main.releaseVersionNumber ?? "0") (\(Bundle.main.buildVersionNumber ?? "0"))"
        Settings.set(setting: .appVersion, versionString)

        setupNetworkMonitoring()
        hlsServer?.listen()

        let window = UIWindow()
        self.window = window
        window.rootViewController = RootViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)
        window.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, handleOpen url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn
            .sharedInstance()
            .handle(url as URL?,
                    sourceApplication: options[.sourceApplication] as? String,
                    annotation: options[.annotation])
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if Settings.get(setting: .backgroundPictureInPicture) as? Bool ?? false && videoPlayer.status.value == .playing && videoPlayer.isPictureInPictureActive.value {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.25) {
                self.videoPlayer.stopPictureInPicture()
            }
        }

        videoPlayer.refreshState()
        incomingVideoReceiver.scanPasteboardForURL()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if Settings.get(setting: .backgroundPictureInPicture) as? Bool ?? false && videoPlayer.status.value == .playing {
            videoPlayer.startPictureInPicture()
        } else if !(Settings.get(setting: .backgroundPlayback) as? Bool ?? true) {
            videoPlayer.pause()
        }
    }

    private func googleSignIn() {
        // Initialize sign-in
        GIDSignIn.sharedInstance().clientID = "1075139575942-l15imga5cglnbvjeir5aoclf9jkf07cf.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self

        var scopes = GIDSignIn.sharedInstance()?.scopes
        scopes?.append("https://www.googleapis.com/auth/youtube")
        GIDSignIn.sharedInstance()?.scopes = scopes

        GIDSignIn.sharedInstance()?.signInSilently()
    }

    private func setupNetworkMonitoring() {
        do {
            Network.reachability = try Reachability(hostname: "www.youtube.com")
            do {
                try Network.reachability?.start()
            } catch let error as Network.Error {
                os_log("Network error: %@", log: .network, type: .fault, error.localizedDescription)
            } catch {
                os_log("Unknown network error: %@", log: .network, type: .fault, error.localizedDescription)
            }
        } catch {
            os_log("Failed to initialize reachability: %@", log: .network, type: .fault, error.localizedDescription)
        }

        NotificationCenter.default.reactive.notifications(forName: .flagsChanged).signal.take(duringLifetimeOf: self).observeValues { _ in
            guard let status = Network.reachability?.status else { return }

            os_log("Status: %@, HostName: %@, Reachable: %@, Wifi: %@, Cellular: %@",
                   log: .network,
                   type: .info,
                   status.description,
                   Network.reachability?.hostname ?? "nil",
                   Network.reachability?.isReachable.description ?? "nil",
                   Network.reachability?.isReachableViaWiFi.description ?? "nil",
                   Network.reachability?.isWWAN.description ?? "nil")
        }
    }
}

extension AppDelegate: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            os_log("Failed to login: %@", log: .googleSignIn, type: .error, error.localizedDescription)
        } else {
            os_log("Logged in as %@", log: .googleSignIn, type: .info, user.profile.name)
            if let accessToken = user.authentication.accessToken {
                YoutubeKit.shared.setAccessToken(accessToken)
                NotificationCenter.default.post(name: .googleSignInSucceeded, object: nil, userInfo: nil)
            }
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error?) {
        os_log("Logged out from user %@ with error: %@", log: .googleSignIn, type: .info, user.profile.name, error?.localizedDescription ?? "nil")
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

extension NSNotification.Name {
    static let googleSignInSucceeded = NSNotification.Name("Google.authentication.loggedIn")
}
