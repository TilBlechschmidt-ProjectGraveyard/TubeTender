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

        self.addChild(playerViewController)
        self.addChild(videoDetailViewController)

        if let playerView = playerViewController.view, let videoDetailView = videoDetailViewController.view {
            let stackView = UIStackView(arrangedSubviews: [playerView, videoDetailView])

            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.distribution = .fill

            let swipeGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDidSwipeVideo(gestureRecognizer:)))
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userDidTapVideo(gestureRecognizer:)))
            playerView.addGestureRecognizer(swipeGestureRecognizer)
            playerView.addGestureRecognizer(tapGestureRecognizer)
            playerView.isUserInteractionEnabled = true

            view.addSubview(stackView)
            stackView.sendSubviewToBack(videoDetailView)
            stackView.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.bottom.equalToSuperview()
            }
        }

        playerViewController.didMove(toParent: self)
        videoDetailViewController.didMove(toParent: self)

        orientationDidChange()

        let blackBar = UIView()
        blackBar.backgroundColor = UIColor.black
        view.addSubview(blackBar)
        blackBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        videoPlayer.currentItem.producer.take(duringLifetimeOf: self).startWithValues { [unowned self] video in
            if let video = video {
                self.videoDetailViewController.video = video
            }
        }
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        orientationDidChange()
    }

    func orientationDidChange() {
        if UIDevice.current.orientation.isLandscape {
            enterFullscreen()
        } else {
            exitFullscreen()
        }
    }

    @objc func userDidSwipeVideo(gestureRecognizer: UIPanGestureRecognizer) {
        // TODO Don't use y component but diagonal instead.
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

    @objc func userDidTapVideo(gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            delegate?.videoViewControllerUserDidTapVideo(self)
        }
    }

    func enterFullscreen(tellPlayerViewController: Bool = true) {
        if tellPlayerViewController {
            playerViewController.isFullscreenActive = true
        }
        playerViewController.view.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    func exitFullscreen(tellPlayerViewController: Bool = true) {
        if tellPlayerViewController {
            playerViewController.isFullscreenActive = false
        }
        playerViewController.view.snp.remakeConstraints { make in
            make.height.equalTo(view.safeAreaLayoutGuide.snp.width).multipliedBy(Constants.defaultAspectRatio)
        }
    }
}

extension VideoViewController: PlayerViewControllerDelegate {
    public func playerViewController(_ playerViewController: PlayerViewController, didChangeFullscreenStatus isFullscreenActive: Bool) {
        if isFullscreenActive {
            enterFullscreen(tellPlayerViewController: false)
        } else {
            exitFullscreen(tellPlayerViewController: false)
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
    func videoViewControllerUserDidTapVideo(_ videoViewController: VideoViewController)
}
