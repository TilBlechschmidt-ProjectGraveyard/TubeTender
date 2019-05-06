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
    let videoViewController: VideoViewController
    let hlsServer: HLSServer?

    override init() {
        commandCenter = CommandCenter()
        videoPlayer = VideoPlayer(commandCenter: commandCenter)
        incomingVideoReceiver = IncomingVideoReceiver(videoPlayer: videoPlayer)
        videoViewController = VideoViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)
        hlsServer = try? HLSServer(port: Constants.hlsServerPort)

        super.init()
        videoViewController.delegate = self
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, options: [])
        } catch {
            os_log("Setting category to AVAudioSessionCategoryPlayback failed.", log: .audio, type: .fault)
        }

        // Override point for customization after application launch.
        YoutubeKit.shared.setAPIKey("AIzaSyDEN6U1W9vvrV5CDgRizZRfd6nHnZZDydU")

        googleSingIn()
        NotificationCenter.default.addObserver(incomingVideoReceiver,
                                               selector: #selector(incomingVideoReceiver.scanPasteboardForURL),
                                               name: UIPasteboard.changedNotification,
                                               object: nil)

        UIVisualEffectView.appearance().effect = UIBlurEffect(style: .dark)

        let versionString = "\(Bundle.main.releaseVersionNumber ?? "0") (\(Bundle.main.buildVersionNumber ?? "0"))"
        Settings.set(setting: .appVersion, versionString)

        setupNetworkMonitoring()
        hlsServer?.listen()

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.rootViewController = createRootTabBarController()
        window.makeKeyAndVisible()
        updateVideoPosition()

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
        if Settings.get(setting: .backgroundPictureInPicture) as? Bool ?? false && videoPlayer.status.value == .playing {
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

    private func createRootTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.tabBar.barStyle = .black
        tabBarController.viewControllers = [
            UINavigationController(rootViewController: SubscriptionFeedViewController(videoPlayer: videoPlayer)),
            UINavigationController(rootViewController: SearchListViewController(videoPlayer: videoPlayer)),
            UINavigationController(rootViewController: QueueListViewController(videoPlayer: videoPlayer)),
            UINavigationController(rootViewController: SignInViewController())
        ]

        videoViewController.viewWillAppear(true)
        tabBarController.view.addSubview(videoViewController.view)
//        videoViewController.view.translatesAutoresizingMaskIntoConstraints = false
//        videoViewController.view.snp.makeConstraints { make in
//            make.right.equalToSuperview().offset(-10)
//            make.bottom.equalTo(tabBarController.tabBar.snp.top).offset(-10)
//            make.width.equalToSuperview().dividedBy(2)
//            make.height.equalTo(videoViewController.view.snp.width).multipliedBy(Constants.defaultAspectRatio)
//        }
        videoViewController.viewDidAppear(true)

        tabBarController.view.addInteraction(UIDropInteraction(delegate: incomingVideoReceiver))
        return tabBarController
    }

    private func googleSingIn() {
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

    var videoPosition: CGFloat = 0

    func updateVideoPosition() {
        videoViewController.videoDetailViewController.view.alpha = CGFloat(videoPosition)

        let frame = window!.frame
        let videoWidth = frame.width * (0.5 + videoPosition / 2)
        let videoHeight = videoWidth * Constants.defaultAspectRatio

        //swiftlint:disable force_cast
        let tabBarController = (window!.rootViewController as! UITabBarController)
        let tabBarPosition = tabBarController.tabBar.convert(tabBarController.tabBar.bounds, to: tabBarController.view).minY

        videoViewController.view.frame = CGRect(
            x: frame.width - videoWidth - (1 - videoPosition) * 10,
            y: (1 - videoPosition) * (tabBarPosition - videoHeight - 10),
            width: videoWidth,
            height: videoHeight + videoPosition * (frame.height - videoHeight))
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

extension AppDelegate: VideoViewControllerDelegate {
    func videoViewController(_ videoViewController: VideoViewController, userDidMoveVideoVertical deltaY: CGFloat) {
        videoPosition -= deltaY / (window!.frame.height / 2)
        videoPosition = min(max(videoPosition, 0), 1)
        self.updateVideoPosition()
    }

    func videoViewController(_ videoViewController: VideoViewController, userDidReleaseVideo velocityY: CGFloat) {
        videoPosition -= velocityY / (window!.frame.height / 2) / 2

        if videoPosition > 0.5 {
            videoPosition = 1
        } else {
            videoPosition = 0
        }

        UIView.animate(withDuration: 0.2) {
            self.updateVideoPosition()
        }
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
