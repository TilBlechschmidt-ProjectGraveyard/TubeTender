//
//  RootViewController.swift
//  TubeTender
//
//  Created by Noah Peeters on 06.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class RootViewController: UITabBarController {
    private let videoViewController: VideoViewController

    private let homeFeedController: HomeFeedViewController
    private let subscriptionFeedController: SubscriptionFeedViewController
    private let searchListController: SearchListViewController
    private let queueListController: QueueListViewController
    private let signInController: SignInViewController

    private let videoPlayer: VideoPlayer

    init(videoPlayer: VideoPlayer, incomingVideoReceiver: IncomingVideoReceiver, subscriptionFeedAPI: SubscriptionFeedAPI) {
        self.videoViewController = VideoViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)
        self.homeFeedController = HomeFeedViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)
        self.subscriptionFeedController = SubscriptionFeedViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver, subscriptionFeedAPI: subscriptionFeedAPI)
        self.searchListController = SearchListViewController(videoPlayer: videoPlayer)
        self.queueListController = QueueListViewController(videoPlayer: videoPlayer)
        self.signInController = SignInViewController()
        self.videoPlayer = videoPlayer

        super.init(nibName: nil, bundle: nil)

        viewControllers = [
            createNavigationController(rootViewController: homeFeedController),
            createNavigationController(rootViewController: subscriptionFeedController),
            createNavigationController(rootViewController: searchListController),
            createNavigationController(rootViewController: queueListController),
            createNavigationController(rootViewController: signInController)
        ]

        videoViewController.delegate = self
        addChild(videoViewController)
        view.addSubview(videoViewController.view)
        videoViewController.viewDidAppear(false)
        videoViewController.didMove(toParent: self)

        videoViewController.view.addDropShadow()

        view.addInteraction(UIDropInteraction(delegate: incomingVideoReceiver))
        tabBar.barStyle = .black

        videoViewController.view.alpha = 0
        videoPlayer.currentItem.signal.take(duringLifetimeOf: self).observeValues { [unowned self] video in
            guard self.videoPosition == 0 else { return }
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5) {
                    self.videoViewController.view.alpha = video == nil ? 0 : 1
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateVideoPosition(animated: true)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async {
            self.updateVideoPosition(animated: true)
        }
    }

    private func createNavigationController(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.barStyle = .blackTranslucent
        return navigationController
    }

    private var videoPosition: CGFloat = 0

    private func updateVideoPosition(animated: Bool) {
        guard !animated else {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.layoutSubviews], animations: {
                self.updateVideoPosition(animated: false)
            }, completion: nil)
            return
        }

        videoViewController.videoDetailViewController.view.alpha = CGFloat(videoPosition)
        videoViewController.view.updateDropShadow()

        if videoPosition == 0 {
            videoViewController.playerViewController.disableControls()
        } else {
            videoViewController.playerViewController.enableControls()
        }

        let videoWidthPercentage: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 0.5 : 0.25
        let videoWidth = view.frame.width * (videoWidthPercentage + videoPosition * (1 - videoWidthPercentage))
        let videoHeight = videoWidth * Constants.defaultAspectRatio

        let tabBarPosition = tabBar.convert(tabBar.bounds, to: view).minY

        videoViewController.view.frame = CGRect(
            x: view.frame.width - videoWidth - (1 - videoPosition) * Constants.uiPadding,
            y: (1 - videoPosition) * (tabBarPosition - videoHeight - Constants.uiPadding),
            width: videoWidth,
            height: videoHeight + videoPosition * (view.frame.height - videoHeight))
    }
}

extension RootViewController {
    private var enableSimpleCommands: Bool {
        return !searchListController.searchBarIsActive
    }

    override public var keyCommands: [UIKeyCommand]? {
        // TODO: bug apple about this!
        guard !Thread.callStackSymbols.joined().contains("__NSFireTimer") else {
            return nil
        }

        let simpleCommands = [
            UIKeyCommand(input: "p", modifierFlags: [], action: #selector(togglePlay)),
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(togglePlay), discoverabilityTitle: "Toggle Play"),
            UIKeyCommand(input: "f", modifierFlags: [], action: #selector(toggleFullscreen), discoverabilityTitle: "Toggle Fullscreen"),

            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(enterFullscreen), discoverabilityTitle: "Enter Fullscreen"),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(exitFullscreen), discoverabilityTitle: "Exit Fullscreen"),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(seekForward), discoverabilityTitle: "Seek forward"),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(seekBackward), discoverabilityTitle: "Seek backward"),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(exitFullscreen))
        ]

        let complexCommands = [
            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(openSearch), discoverabilityTitle: "Search"),
            UIKeyCommand(input: "1", modifierFlags: .command, action: #selector(goToHomeFeedTab), discoverabilityTitle: "Home Tab"),
            UIKeyCommand(input: "2", modifierFlags: .command, action: #selector(goToSubscriptionsFeedTab), discoverabilityTitle: "Subscription Tab"),
            UIKeyCommand(input: "3", modifierFlags: .command, action: #selector(goToSearchTab), discoverabilityTitle: "Search Tab"),
            UIKeyCommand(input: "4", modifierFlags: .command, action: #selector(goToQueueTab), discoverabilityTitle: "Queue Tab"),
            UIKeyCommand(input: "5", modifierFlags: .command, action: #selector(goToSignInTab), discoverabilityTitle: "SignIn Tab"),

            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: .shift, action: #selector(seekForwardFast), discoverabilityTitle: "Seek forward fast"),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: .shift, action: #selector(seekBackwardFast), discoverabilityTitle: "Seek backward fast"),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: .command, action: #selector(nextVideo), discoverabilityTitle: "Next Video"),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: .command, action: #selector(previousVideo), discoverabilityTitle: "Previous Video")
        ]

        return complexCommands + (enableSimpleCommands ? simpleCommands : [])
    }

    @objc func togglePlay() {
        videoPlayer.togglePlay()
    }

    @objc private func toggleFullscreen() {
        videoPosition = videoPosition == 0 ? 1 : 0
        updateVideoPosition(animated: true)
    }

    @objc private func enterFullscreen() {
        videoPosition = 1
        updateVideoPosition(animated: true)
    }

    @objc private func exitFullscreen() {
        videoPosition = 0
        updateVideoPosition(animated: true)
    }

    private func goToTab(withIndex index: Int) {
        exitFullscreen()
        self.selectedIndex = index
    }

    @objc private func goToHomeFeedTab() {
        goToTab(withIndex: 0)
    }

    @objc private func goToSubscriptionsFeedTab() {
        goToTab(withIndex: 1)
    }

    @objc private func goToSearchTab() {
        goToTab(withIndex: 2)
    }

    @objc private func goToQueueTab() {
        goToTab(withIndex: 3)
    }

    @objc private func goToSignInTab() {
        goToTab(withIndex: 4)
    }

    @objc private func openSearch() {
        goToSearchTab()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.searchListController.enterSearchBar()
        }
    }

    @objc private func seekForward() {
        videoPlayer.seek(by: 10)
    }

    @objc private func seekForwardFast() {
        videoPlayer.seek(by: 30)
    }

    @objc private func seekBackward() {
        videoPlayer.seek(by: -10)
    }

    @objc private func seekBackwardFast() {
        videoPlayer.seek(by: -30)
    }

    @objc private func nextVideo() {
        videoPlayer.next()
    }

    @objc private func previousVideo() {
        videoPlayer.previous()
    }
}

extension RootViewController: VideoViewControllerDelegate {
    func videoViewController(_ videoViewController: VideoViewController, userDidMoveVideoVertical deltaY: CGFloat) {
        videoPosition -= deltaY / (view.frame.height / 2)
        videoPosition = min(max(videoPosition, 0), 1)
        self.updateVideoPosition(animated: false)
    }

    func videoViewController(_ videoViewController: VideoViewController, userDidReleaseVideo velocityY: CGFloat) {
        videoPosition -= velocityY / (view.frame.height / 2) / 2

        if videoPosition > 0.5 {
            videoPosition = 1
        } else {
            videoPosition = 0
        }

        updateVideoPosition(animated: true)
    }

    func videoViewControllerUserDidTapVideo(_ videoViewController: VideoViewController) {
        videoPosition = 1
        updateVideoPosition(animated: true)
    }
}
