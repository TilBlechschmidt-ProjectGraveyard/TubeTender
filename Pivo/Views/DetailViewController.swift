//
//  DetailViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 13.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    private let logoView = UIImageView()
    private let videoView = UIView()
    private let playerViewController = PlayerViewController()
    private let videoDetailViewController = VideoDetailViewController()

    private var fullscreenConstraints: [NSLayoutConstraint] = []
    private var regularConstraints: [NSLayoutConstraint] = []

    override func viewDidLoad() {

        view.backgroundColor = UIColor(red: 0.141, green: 0.141, blue: 0.141, alpha: 1)

        // PlayerViewController setup
        playerViewController.delegate = self
        playerViewController.playbackManager = PlaybackManager.shared
//        playerViewController.playbackManager.enqueue(videoID: "1La4QzGeaaQ")
//        playerViewController.playbackManager.enqueue(videoID: "_zeFohwlYtI")
        playerViewController.playbackManager.preferQuality = .hd1080
//        PlaybackManager.shared.next().start()

        // Logo view setup
        logoView.alpha = 1
        logoView.image = UIImage(named: "logo_grey")
        logoView.contentMode = .scaleAspectFit
        view.addSubview(logoView)
        logoView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.20),
            logoView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.20)
        ])

        // Video view setup
        videoView.alpha = 0
        videoView.backgroundColor = UIColor(red: 0.141, green: 0.141, blue: 0.141, alpha: 1)
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

        if let playerView = playerViewController.view, let videoDetailView = videoDetailViewController.view {
            // Add the player
            videoView.addSubview(playerView)
            playerView.translatesAutoresizingMaskIntoConstraints = false
            videoView.addConstraints([
                playerView.topAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.topAnchor),
                playerView.leftAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.leftAnchor),
                playerView.rightAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.rightAnchor)
            ])
            regularConstraints.append(
                playerView.heightAnchor.constraint(equalTo: videoView.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5625)
            )
            fullscreenConstraints.append(
//                playerView.heightAnchor.constraint(equalTo: videoView.heightAnchor)
                playerView.bottomAnchor.constraint(equalTo: videoView.bottomAnchor)
            )

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
        }

        if let playbackManager = playerViewController.playbackManager,
            let currentlyPlaying = playbackManager.currentlyPlaying {
            willLoadVideo(withID: currentlyPlaying.id, animate: false)
        }

        regularConstraints.forEach { $0.isActive = true }
    }

    func willLoadVideo(withID videoID: VideoID, animate: Bool) {
        DispatchQueue.main.async {
            if self.videoView.alpha < 1 {
                UIView.animate(withDuration: animate ? 0.5 : 0) {
                    self.videoView.alpha = 1
                    self.logoView.alpha = 0
                }
            }
            self.videoDetailViewController.videoID = videoID
        }
    }
}

extension DetailViewController: PlayerViewControllerDelegate {
    func playerViewController(_ playerViewController: PlayerViewController, didChangeFullscreenStatus isFullscreenActive: Bool) {
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

    func playerViewController(_ playerViewController: PlayerViewController, willLoadVideo videoID: VideoID) {
        willLoadVideo(withID: videoID, animate: true)
    }

    func playerViewControllerDidEmptyQueue(_ playerViewController: PlayerViewController) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.videoView.alpha = 0
                self.logoView.alpha = 1
            }
        }
    }
}
