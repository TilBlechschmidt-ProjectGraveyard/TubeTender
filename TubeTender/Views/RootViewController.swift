//
//  RootViewController.swift
//  TubeTender
//
//  Created by Noah Peeters on 06.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class RootViewController: UITabBarController {
    let videoViewController: VideoViewController

    init(videoPlayer: VideoPlayer, incomingVideoReceiver: IncomingVideoReceiver, subscriptionFeedAPI: SubscriptionFeedAPI) {
        videoViewController = VideoViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)
        super.init(nibName: nil, bundle: nil)

        viewControllers = [
            createNavigationController(rootViewController: HomeFeedViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)),
            createNavigationController(rootViewController: SubscriptionFeedViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver, subscriptionFeedAPI: subscriptionFeedAPI)),
            createNavigationController(rootViewController: SearchListViewController(videoPlayer: videoPlayer)),
            createNavigationController(rootViewController: QueueListViewController(videoPlayer: videoPlayer)),
            createNavigationController(rootViewController: SignInViewController())
        ]

        videoViewController.delegate = self
        videoViewController.viewWillAppear(false)
        view.addSubview(videoViewController.view)
        videoViewController.viewDidAppear(false)

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
        updateVideoPosition()
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        videoViewController.viewWillTransition(to: size, with: coordinator)
        updateVideoPosition()
    }

    private func createNavigationController(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.barStyle = .blackTranslucent
        return navigationController
    }

    private var videoPosition: CGFloat = 0

    private func updateVideoPosition() {
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

extension RootViewController: VideoViewControllerDelegate {
    func videoViewController(_ videoViewController: VideoViewController, userDidMoveVideoVertical deltaY: CGFloat) {
        videoPosition -= deltaY / (view.frame.height / 2)
        videoPosition = min(max(videoPosition, 0), 1)
        self.updateVideoPosition()
    }

    func videoViewController(_ videoViewController: VideoViewController, userDidReleaseVideo velocityY: CGFloat) {
        videoPosition -= velocityY / (view.frame.height / 2) / 2

        if videoPosition > 0.5 {
            videoPosition = 1
        } else {
            videoPosition = 0
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: [.layoutSubviews], animations: {
            self.updateVideoPosition()
        })
    }

    func videoViewControllerUserDidTapVideo(_ videoViewController: VideoViewController) {
        videoPosition = 1

        UIView.animate(withDuration: 0.2, delay: 0, options: [.layoutSubviews], animations: {
            self.updateVideoPosition()
        })
    }
}

