//
//  VideoViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 13.11.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

public class VideoViewController: UIViewController {
    private let emptyStateView = EmptyStateView(image: #imageLiteral(resourceName: "camera"), text: "No video selected")
    private let videoView = UIView()
    let playerViewController: PlayerViewController
    let videoDetailViewController = VideoMetadataViewController()

    private var fullscreenConstraints: [NSLayoutConstraint] = []
    private var regularConstraints: [NSLayoutConstraint] = []

    private let videoPlayer: VideoPlayer
    private let incomingVideoReceiver: IncomingVideoReceiver

    public weak var delegate: VideoViewControllerDelegate?

    init(videoPlayer: VideoPlayer, incomingVideoReceiver: IncomingVideoReceiver) {
        self.videoPlayer = videoPlayer
        self.incomingVideoReceiver = incomingVideoReceiver
        self.playerViewController = PlayerViewController(videoPlayer: videoPlayer)
        super.init(nibName: nil, bundle: nil)

        videoDetailViewController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //swiftlint:disable:next function_body_length
    override public func viewDidLoad() {
        view.backgroundColor = Constants.backgroundColor

        // PlayerViewController setup
        playerViewController.delegate = self

        // Logo view setup
        emptyStateView.alpha = 1
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }

        // Video view setup
        videoView.alpha = 0
        videoView.backgroundColor = Constants.backgroundColor
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false

        //TODO: use snapkit
        view.addConstraints([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

        if let playerView = playerViewController.view, let videoDetailView = videoDetailViewController.view {
            self.addChild(playerViewController)
            self.addChild(videoDetailViewController)

            // Add the player
            videoView.addSubview(playerView)
            playerView.translatesAutoresizingMaskIntoConstraints = false
            videoView.addConstraints([
                playerView.topAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.topAnchor),
                playerView.leftAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.leftAnchor),
                playerView.rightAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.rightAnchor)
            ])
            regularConstraints.append(
                playerView.heightAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.widthAnchor, multiplier: Constants.defaultAspectRatio)
            )
            fullscreenConstraints.append(
                //                playerView.heightAnchor.constraint(equalTo: videoView.heightAnchor)
                playerView.bottomAnchor.constraint(equalTo: videoView.bottomAnchor)
            )

            let swipeGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDidSwipeVideo(gestureRecognizer:)))
            playerView.addGestureRecognizer(swipeGestureRecognizer)
            playerView.isUserInteractionEnabled = true

            // Add a black bar to fill the top safe area
            let blackBar = UIView()
            blackBar.backgroundColor = UIColor.black
            blackBar.translatesAutoresizingMaskIntoConstraints = false
            videoView.addSubview(blackBar)
            videoView.addConstraints([
                blackBar.topAnchor.constraint(equalTo: videoView.topAnchor),
                blackBar.bottomAnchor.constraint(equalTo: playerView.topAnchor),
                blackBar.leftAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.leftAnchor),
                blackBar.rightAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.rightAnchor)
            ])

            // Add the video details
            videoView.addSubview(videoDetailView)
            videoDetailView.translatesAutoresizingMaskIntoConstraints = false
            videoView.addConstraints([
                videoDetailView.topAnchor.constraint(equalTo: playerView.bottomAnchor),
                videoDetailView.bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
                videoDetailView.leftAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.leftAnchor),
                videoDetailView.rightAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.rightAnchor)
            ])
            videoView.sendSubviewToBack(videoDetailView)

            videoDetailViewController.didMove(toParent: self)
            playerViewController.didMove(toParent: self)
        }

        regularConstraints.forEach { $0.isActive = true }

        videoPlayer.currentItem.producer.take(duringLifetimeOf: self).startWithValues { [unowned self] video in
            if let video = video {
                self.videoDetailViewController.video = video
                UIView.animate(withDuration: 0.5) {
                    self.videoView.alpha = 1
                    self.emptyStateView.alpha = 0
                }
            } else {
                UIView.animate(withDuration: 0.5) {
                    self.videoView.alpha = 0
                    self.emptyStateView.alpha = 1
                }
            }
        }
    }

    @objc func userDidSwipeVideo(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .changed:
            let translation = gestureRecognizer.translation(in: playerViewController.view)
            gestureRecognizer.setTranslation(.zero, in: playerViewController.view)
            delegate?.videoViewController(self, userDidMoveVideoVertical: translation.y)
        case .ended:
            let velocity = gestureRecognizer.velocity(in: playerViewController.view)
            delegate?.videoViewController(self, userDidReleaseVideo: velocity.y)
        default:
            break
        }
    }
}

extension VideoViewController: PlayerViewControllerDelegate {
    public func playerViewController(_ playerViewController: PlayerViewController, didChangeFullscreenStatus isFullscreenActive: Bool) {
        if isFullscreenActive {
            self.regularConstraints.forEach { $0.isActive = false }
            self.fullscreenConstraints.forEach { $0.isActive = true }
        } else {
            self.fullscreenConstraints.forEach { $0.isActive = false }
            self.regularConstraints.forEach { $0.isActive = true }
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}

extension VideoViewController: VideoMetadataViewControllerDelegate {
    public func handle(url: URL, rect: CGRect, view: UIView) -> Bool {
        return !incomingVideoReceiver.handle(url: url, source: .rect(rect: rect, view: view, permittedArrowDirections: .any))
    }
}

public protocol VideoViewControllerDelegate: class {
    func videoViewController(_ videoViewController: VideoViewController, userDidMoveVideoVertical deltaY: CGFloat)
    func videoViewController(_ videoViewController: VideoViewController, userDidReleaseVideo velocityY: CGFloat)
}
