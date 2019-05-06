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

    init(videoPlayer: VideoPlayer, incomingVideoReceiver: IncomingVideoReceiver) {
        videoViewController = VideoViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)
        super.init(nibName: nil, bundle: nil)

        viewControllers = [
            createNavigationController(rootViewController: HomeFeedViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)),
            createNavigationController(rootViewController: SubscriptionFeedViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver)),
            createNavigationController(rootViewController: SearchListViewController(videoPlayer: videoPlayer)),
            createNavigationController(rootViewController: QueueListViewController(videoPlayer: videoPlayer)),
            createNavigationController(rootViewController: SignInViewController())
        ]

        videoViewController.delegate = self
        videoViewController.viewWillAppear(false)
        view.addSubview(videoViewController.view)
        videoViewController.viewDidAppear(false)

        view.addInteraction(UIDropInteraction(delegate: incomingVideoReceiver))
        tabBar.barStyle = .black
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
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

        let videoWidth = view.frame.width * (0.5 + videoPosition / 2)
        let videoHeight = videoWidth * Constants.defaultAspectRatio

        let tabBarPosition = tabBar.convert(tabBar.bounds, to: view).minY

        videoViewController.view.frame = CGRect(
            x: view.frame.width - videoWidth - (1 - videoPosition) * 10,
            y: (1 - videoPosition) * (tabBarPosition - videoHeight - 10),
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

        UIView.animate(withDuration: 0.2) {
            self.updateVideoPosition()
        }
    }
}

