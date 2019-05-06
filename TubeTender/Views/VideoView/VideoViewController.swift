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

    override public func viewDidLoad() {
        view.backgroundColor = Constants.backgroundColor

        // PlayerViewController setup
        playerViewController.delegate = self

        // Logo view setup
        emptyStateView.alpha = 1
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeEdgesEqualToSuperview()

        // Video view setup
        videoView.alpha = 0
        videoView.backgroundColor = Constants.backgroundColor
        view.addSubview(videoView)
        videoView.snp.makeEdgesEqualToSuperview()

        playerViewController.willMove(toParent: self)
        videoDetailViewController.willMove(toParent: self)

        self.addChild(playerViewController)
        self.addChild(videoDetailViewController)

        if let playerView = playerViewController.view, let videoDetailView = videoDetailViewController.view {
            let stackView = UIStackView(arrangedSubviews: [playerView, videoDetailView])

            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.distribution = .fill

            let swipeGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDidSwipeVideo(gestureRecognizer:)))
            playerView.addGestureRecognizer(swipeGestureRecognizer)
            playerView.isUserInteractionEnabled = true

            videoView.addSubview(stackView)
            stackView.sendSubviewToBack(videoDetailView)
//            stackView.snp.makeEdgesEqualToSuperview()
            stackView.snp.makeConstraints { make in
                make.edges.equalTo(videoView.safeAreaLayoutGuide)
//                make.top.equalTo(videoView.safeAreaLayoutGuide.snp.top)
//                make.left.equalTo(videoView.safeAreaLayoutGuide.snp.left)
//                make.left.equalTo(videoView.safeAreaLayoutGuide.snp.right)
//                make.bottom.equalTo(videoView.safeAreaLayoutGuide.snp.bottom)
            }
        }

        playerViewController.didMove(toParent: self)
        videoDetailViewController.didMove(toParent: self)

        exitFullscreen()

//        t blackBar = UIView()
//        blackBar.backgroundColor = UIColor.black
//        blackBar.translatesAutoresizingMaskIntoConstraints = false
//        videoView.addSubview(blackBar)
//        videoView.addConstraints([
//            blackBar.topAnchor.constraint(equalTo: videoView.topAnchor),
//            blackBar.bottomAnchor.constraint(equalTo: playerView.topAnchor),
//            blackBar.leftAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.leftAnchor),
//            blackBar.rightAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.rightAnchor)
//            ])

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

    func enterFullscreen() {
        playerViewController.view.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    func exitFullscreen() {
        playerViewController.view.snp.remakeConstraints { make in
            make.height.equalTo(videoView.safeAreaLayoutGuide.snp.width).multipliedBy(Constants.defaultAspectRatio)
        }
    }
}

extension VideoViewController: PlayerViewControllerDelegate {
    public func playerViewController(_ playerViewController: PlayerViewController, didChangeFullscreenStatus isFullscreenActive: Bool) {
        if isFullscreenActive {
            enterFullscreen()
        } else {
            exitFullscreen()
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
