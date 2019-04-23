//
//  PlayerViewNew.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 05.11.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

protocol PlayerViewControllerDelegate: class {
    func playerViewController(_ playerViewController: PlayerViewController, didChangeFullscreenStatus: Bool)
}

class PlayerViewController: UIViewController {
    let contentViewController = UIViewController()
    let playerControlView = PlayerControlView()
    let videoView = UIView()
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
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    override func viewDidLoad() {
        attachContentView()

        let contentView = contentViewController.view!

        contentView.backgroundColor = UIColor.black

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

        videoView.addSubview(VideoPlayer.shared.playerView)
        VideoPlayer.shared.playerView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }

        let player = VideoPlayer.shared

        player.status.combinePrevious(.noMediaLoaded).signal.observeValues { previous, current in
            if previous != .playing && current == .playing {
                self.refreshControlHideTimer()
            }
        }

        // Play button
        playerControlView.playButton.reactive.isPlaying <~ player.status.map { $0 == .playing }
        playerControlView.playButton.reactive.controlEvents(.touchUpInside).take(duringLifetimeOf: self).observeValues { _ in
            if player.status.value == .playing {
                player.pause()
            } else {
                player.play()
            }
        }

        // PiP button
        playerControlView.pictureInPictureButton.reactive.controlEvents(.touchUpInside).observeValues { _ in
            player.startPictureInPicture()
        }

        // Duration & Elapsed time
        // TODO Different value when .noMediaLoaded
        playerControlView.elapsedTimeLabel.reactive.text <~ player.currentTime.map { PlayerViewController.stringRepresentation(ofTime: $0) }
        playerControlView.durationLabel.reactive.text <~ player.duration.map { PlayerViewController.stringRepresentation(ofTime: $0) }

        // Slider & Progress bar
        playerControlView.progressBar.reactive.progress <~ player.currentTime.map { return Float($0 / player.duration.value) }
        playerControlView.seekingSlider.reactive.value <~ player.currentTime.signal.observe(on: QueueScheduler.main).filterMap { [unowned self] time in
            return self.playerControlView.seekingSlider.isTracking ? nil : Float(time / player.duration.value)
        }
        playerControlView.seekingSlider.reactive.values.take(duringLifetimeOf: self).observeValues { player.seek(toPercentage: Double($0)) }

        // Add controls
        contentView.addSubview(playerControlView)
        playerControlView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraints([
            playerControlView.topAnchor.constraint(equalTo: videoView.topAnchor),
            playerControlView.bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
            playerControlView.leftAnchor.constraint(equalTo: videoView.leftAnchor),
            playerControlView.rightAnchor.constraint(equalTo: videoView.rightAnchor)
        ])

        let isBuffering = player.status.signal.take(duringLifetimeOf: self).map { $0 == .buffering }
        playerControlView.loadingIndicator.reactive.isAnimating <~ isBuffering
        isBuffering.observeValues { buffering in
            if buffering {
                self.controlsVisible = false
            }
        }

        player.isPictureInPictureActive.signal.observe(on: QueueScheduler.main).take(duringLifetimeOf: self).observeValues { [unowned self] pipActive in
            self.controlsDisabled = pipActive
            if pipActive {
                self.isFullscreenActive = false
            }
            UIView.animate(withDuration: 0.5) {
                self.playerControlView.controlView.alpha = pipActive ? 0 : 1
            }
        }

        // Bind gesture recognizers
        // TODO Also handle touchDragOutside if touchdown originated inside the slider
        playerControlView.seekingSlider.addTarget(self, action: #selector(self.seeked), for: .touchDragInside)
        playerControlView.seekingSlider.addTarget(self, action: #selector(self.seeked), for: .touchDragOutside)
        playerControlView.playButton.addTarget(self, action: #selector(self.playButtonTapped), for: .touchUpInside)
        playerControlView.qualityButton.addTarget(self, action: #selector(self.qualityButtonTapped), for: .touchUpInside)
        playerControlView.pictureInPictureButton.addTarget(self,
                                                           action: #selector(self.pictureInPictureTapped),
                                                           for: .touchUpInside)
        playerControlView.fullscreenButton.addTarget(self,
                                                     action: #selector(self.fullscreenButtonTapped),
                                                     for: .touchUpInside)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.viewTapped))
        playerControlView.addGestureRecognizer(tapGestureRecognizer)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewDoubleTapped(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tapGestureRecognizer.require(toFail: doubleTapGesture)
        playerControlView.addGestureRecognizer(doubleTapGesture)

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
    var controlsDisabled = false
    var controlsVisible: Bool {
        get {
            return self.playerControlView.controlView.alpha == 1
        }
        set {
            UIView.animate(withDuration: 0.1) {
                self.playerControlView.controlView.alpha = newValue ? 1.0 : 0.0
            }
        }
    }

    func refreshControlHideTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(self.idleTimerExceeded), userInfo: nil, repeats: false)
    }

    @objc func idleTimerExceeded(_ sender: Timer) {
        if playerControlView.seekingSlider.isTracking || VideoPlayer.shared.status.value != .playing {
            refreshControlHideTimer()
        } else {
            controlsVisible = false
        }
    }

    @objc func viewTapped() {
        //swiftlint:disable:next toggle_bool
        controlsVisible = !controlsVisible && !controlsDisabled

        if controlsVisible {
            refreshControlHideTimer()
        }
    }

    @objc func viewDoubleTapped(_ sender: UITapGestureRecognizer) {
        self.refreshControlHideTimer()
        // TODO Implement exponential growth after a few steps
        // TODO Add animation to indicate seeking visually
        let tapPoint = sender.location(in: self.view)
        if tapPoint.x > self.view.bounds.width / 2 {
            VideoPlayer.shared.seek(by: 10)
        } else {
            VideoPlayer.shared.seek(by: -10)
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

    @objc func qualityButtonTapped() {
        let alert = UIAlertController(title: "Current quality: --", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = playerControlView.topRightControlView
//        alert.popoverPresentationController?.sourceRect = playerControlView.bounds
        alert.popoverPresentationController?.permittedArrowDirections = .any
        alert.popoverPresentationController?.backgroundColor = Constants.backgroundColor
        alert.view.tintColor = .lightGray

        alert.reactive.attributedTitle <~ VideoPlayer.shared.currentQuality.map { NSAttributedString(string: "Current quality: \($0?.description ?? "--")") }

        let currentQuality = VideoPlayer.shared.preferredQuality.value

        let action = UIAlertAction(title: "Automatic", style: .default) { _ in
            VideoPlayer.shared.preferredQuality.value = nil
        }
        if currentQuality == nil {
            action.setValue(true, forKey: "checked")
        }
        alert.addAction(action)

        // TODO Filter actually available qualities
        StreamQuality.ascendingOrder.reversed().forEach { quality in
            let action = UIAlertAction(title: quality.description, style: .default) { _ in
                VideoPlayer.shared.preferredQuality.value = quality
            }

            if let currentQuality = currentQuality, quality == currentQuality {
                action.setValue(true, forKey: "checked")
            }

            alert.addAction(action)
        }

        self.present(alert, animated: true, completion: nil)
    }

    @objc func fullscreenButtonTapped() {
        isFullscreenActive.toggle()
    }

    @objc func seeked() {
        self.refreshControlHideTimer()
    }

    @objc func playButtonTapped() {
        self.refreshControlHideTimer()
    }

    @objc func pictureInPictureTapped() {
        self.refreshControlHideTimer()
    }

    private static func stringRepresentation(ofTime time: Int32) -> String {
        return stringRepresentation(ofTime: Double(time) / 1000)
    }

    private static func stringRepresentation(ofTime time: TimeInterval) -> String {
        let timeInSeconds = Int32(time)
        let (hours, minutes, seconds) = (timeInSeconds / 3600, (timeInSeconds % 3600) / 60, timeInSeconds % 60)
        let output = String(format: "%02d:%02d", minutes, seconds)
        return hours > 0 ? String(format: "%02d:%@", hours, output) : output
    }
}
