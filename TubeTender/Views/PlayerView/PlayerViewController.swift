//
//  PlayerViewNew.swift
//  Pivo
//
//  Created by Til Blechschmidt on 05.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit

protocol PlayerViewControllerDelegate: class {
    func playerViewController(_ playerViewController: PlayerViewController, willLoadVideo withID: VideoID)
    func playerViewControllerDidEmptyQueue(_ playerViewController: PlayerViewController)
    func playerViewController(_ playerViewController: PlayerViewController, didChangeFullscreenStatus: Bool)
}

class PlayerViewController: UIViewController {
    var contentViewController = UIViewController()
    var playbackManager: PlaybackManager!
    var playerControlView = PlayerControlView()
    var videoView = UIView()
    var mediaDuration: Int32?

    weak var delegate: PlayerViewControllerDelegate?

    func attachContentView() {
        let contentView = contentViewController.view!
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
    }

    override func viewDidLoad() {
        attachContentView()

        let contentView = contentViewController.view!

        contentView.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)

        // TODO Add the logo in the center of the video

        playbackManager.drawable = videoView
        playbackManager.delegate = self

        // Add video view
        videoView.removeFromSuperview()
        contentView.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraints([
            videoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            videoView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            videoView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])

        // Add controls
        contentView.addSubview(playerControlView)
        playerControlView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraints([
            playerControlView.topAnchor.constraint(equalTo: videoView.topAnchor),
            playerControlView.bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
            playerControlView.leftAnchor.constraint(equalTo: videoView.leftAnchor),
            playerControlView.rightAnchor.constraint(equalTo: videoView.rightAnchor)
        ])

        // Bind gesture recognizers
        // TODO Also handle touchDragOutside if touchdown originated inside the slider
        playerControlView.seekingSlider.addTarget(self, action: #selector(self.seeked), for: .touchDragInside)
        playerControlView.seekingSlider.addTarget(self, action: #selector(self.seeked), for: .touchDragOutside)
        playerControlView.playButton.addTarget(self, action: #selector(self.playButtonTapped), for: .touchUpInside)
        playerControlView.pictureInPictureButton.addTarget(self,
                                                           action: #selector(self.pictureInPictureTapped),
                                                           for: .touchUpInside)
        playerControlView.fullscreenButton.addTarget(self,
                                                     action: #selector(self.fullscreenButtonTapped),
                                                     for: .touchUpInside)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.viewTapped))
        playerControlView.addGestureRecognizer(tapGestureRecognizer)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.viewPinched))
        playerControlView.addGestureRecognizer(pinchGestureRecognizer)
    }

    private(set) var isFullscreenActive = false {
        didSet {
            if let splitViewController = UIApplication.shared.keyWindow?.rootViewController as? SplitViewController {
                UIView.animate(withDuration: 0.25) {
                    if self.isFullscreenActive {
                        splitViewController.preferredDisplayMode = .primaryHidden
                    } else {
                        splitViewController.preferredDisplayMode = .automatic
                    }

                    self.playerControlView.isFullscreenActive = self.isFullscreenActive
                    self.delegate?.playerViewController(self, didChangeFullscreenStatus: self.isFullscreenActive)

                    self.refreshControlHideTimer()
                }
            }
        }
    }

    var idleTimer: Timer?
    var controlsVisible: Bool {
        get {
            return self.playerControlView.controlView.alpha == 1
        }
        set {
            UIView.animate(withDuration: 0.4, animations: {
                self.playerControlView.controlView.alpha = newValue ? 1.0 : 0.0
                return
            })
        }
    }

    func refreshControlHideTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.idleTimerExceeded), userInfo: nil, repeats: false)
    }

    @objc func idleTimerExceeded(_ sender: Timer) {
        if playerControlView.seekingSlider.isTracking {
            refreshControlHideTimer()
        } else { // TODO Add check if video is playing
            controlsVisible = false
        }
    }

    @objc func viewTapped() {
        refreshControlHideTimer()
        if !controlsVisible {
            controlsVisible = true
        }
    }

    @objc func viewPinched(_ sender: UIPinchGestureRecognizer) {
        let scale = sender.scale
        if sender.state == .ended {
            if scale > 1.25 {
                isFullscreenActive = true
            } else if scale < 0.75 {
                isFullscreenActive = false
            }
        }
    }

    @objc func fullscreenButtonTapped() {
        isFullscreenActive = !isFullscreenActive
    }

    @objc func seeked() {
        playerControlView.seekingSlider.flatMap { playbackManager.seek(to: Double($0.value)) }
        self.refreshControlHideTimer()
    }

    @objc func playButtonTapped() {
        if playerControlView.playButton.isSelected {
            playbackManager.play()
        } else {
            playbackManager.pause()
        }

        self.refreshControlHideTimer()
    }

    @objc func pictureInPictureTapped() {
        DispatchQueue.main.async {
            if self.playbackManager.isPictureInPictureActive {
                self.playbackManager.stopPictureInPicture()
            } else {
                _ = try? self.playbackManager.startPictureInPicture()
            }

            self.refreshControlHideTimer()
        }
    }
}

extension PlayerViewController: PlaybackManagerDelegate {
    func playbackManagerDidFinishPlayback(_ playbackManager: PlaybackManager) {
        // TODO Show an abortable countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // TODO Show errors that might originate here
            self.playbackManager.next().start()
            self.controlsVisible = true
        }
    }

    func playbackManagerDidStartPlayback(_ playbackManager: PlaybackManager) {
        DispatchQueue.main.async {
            self.playerControlView.playButton.deselect()
        }
    }

    func playbackManagerDidStopPlayback(_ playbackManager: PlaybackManager) {
        DispatchQueue.main.async {
            self.playerControlView.playButton.select()
            self.controlsVisible = true
        }
    }

    func playbackManager(_ playbackManager: PlaybackManager, didChangeTime time: Int32) {
        DispatchQueue.main.async {
            let position: Float = Float(time) / Float(self.mediaDuration ?? 0)
            self.playerControlView.progressBar.setProgress(position, animated: true)
            self.playerControlView.elapsedTime.text = self.stringRepresentation(ofTime: time)

            if !self.playerControlView.seekingSlider.isTracking {
                self.playerControlView.seekingSlider.setValue(position, animated: true)
            }
        }
    }

    func playbackManagerWillLoadMedia(_ playbackManager: PlaybackManager, withID: VideoID) {
        DispatchQueue.main.async {
            self.delegate?.playerViewController(self, willLoadVideo: withID)
            self.playerControlView.elapsedTime.text = "--:--"
            self.playerControlView.durationLabel.text = "--:--"
            self.playerControlView.progressBar.setProgress(0, animated: true)
            self.playerControlView.seekingSlider.setValue(0, animated: true)
            self.playerControlView.controlView.alpha = 0
            self.playerControlView.loadingIndicator.startAnimating()
            self.refreshControlHideTimer()
        }
    }

    func playbackManagerDidLoadMedia(_ playbackManager: PlaybackManager, withDuration duration: Int32) {
        DispatchQueue.main.async {
            self.mediaDuration = duration
            self.playerControlView.controlView.alpha = 1
            self.playerControlView.loadingIndicator.stopAnimating()
            self.playerControlView.durationLabel.text = self.stringRepresentation(ofTime: duration)
            self.refreshControlHideTimer()
        }
    }

    func playbackManagerDidEmptyQueue(_ playbackManager: PlaybackManager) {
        self.delegate?.playerViewControllerDidEmptyQueue(self)
        self.controlsVisible = true
    }

    func playbackManagerWillStartPictureInPicture(_ playbackManager: PlaybackManager) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.playerControlView.controlView.alpha = 0
            }
        }
    }

    func playbackManagerWillStopPictureInPicture(_ playbackManager: PlaybackManager) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.playerControlView.controlView.alpha = 1
                self.refreshControlHideTimer()
            }
        }
    }

    private func stringRepresentation(ofTime time: Int32) -> String {
        let timeInSeconds = Int32(Double(time) / 1000)

        let (hours, minutes, seconds) = (timeInSeconds / 3600, (timeInSeconds % 3600) / 60, timeInSeconds % 60)
        let output = String(format: "%02d:%02d", minutes, seconds)
        return hours > 0 ? String(format: "%02d:%@", hours, output) : output
    }
}
