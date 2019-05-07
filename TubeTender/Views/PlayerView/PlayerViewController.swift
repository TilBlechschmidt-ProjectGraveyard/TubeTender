//
//  PlayerViewNew.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 05.11.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

public class PlayerViewController: UIViewController {
    private let contentViewController = UIViewController()
    private let playerControlView = PlayerControlView()
    private let videoView = UIView()
    private var mediaDuration: Int32?
    private let videoPlayer: VideoPlayer

    public weak var delegate: PlayerViewControllerDelegate?

    init(videoPlayer: VideoPlayer) {
        self.videoPlayer = videoPlayer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        setupSubviews()
        setupGestureRecognizer()

        videoView.addSubview(videoPlayer.playerView)
        videoPlayer.playerView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }

        videoPlayer.status.combinePrevious(.noMediaLoaded).signal.observeValues { previous, current in
            if previous != .playing && current == .playing {
                self.refreshControlHideTimer()
            }
        }

        // Play button
        playerControlView.playButton.reactive.isPlaying <~ videoPlayer.status.map { $0 == .playing }
        playerControlView.playButton.reactive.controlEvents(.touchUpInside).take(duringLifetimeOf: self).observeValues { _ in
            if self.videoPlayer.status.value == .playing {
                self.videoPlayer.pause()
            } else {
                self.videoPlayer.play()
            }
        }

        // Picture in picture button
        playerControlView.pictureInPictureButton.reactive.controlEvents(.touchUpInside).observeValues { _ in
            self.videoPlayer.startPictureInPicture()
        }

        // Duration & Elapsed time
        // TODO Different value when .noMediaLoaded
        playerControlView.durationLabel.reactive.text <~ videoPlayer.duration.map(PlayerViewController.stringRepresentation(ofTime:))

        // Slider & Progress bar
        playerControlView.progressBar.reactive.progress <~ Property.combineLatest(videoPlayer.currentTime, videoPlayer.duration)
            .map { Float($0 / $1) }

        playerControlView.seekingSlider.reactive.value <~ Property.combineLatest(videoPlayer.currentTime, videoPlayer.duration)
            .producer
            .take(duringLifetimeOf: self)
            .observe(on: QueueScheduler.main)
            .filter { [unowned self] _ in !self.playerControlView.seekingSlider.isTracking }
            .map { Float($0 / $1) }

        playerControlView.elapsedTimeLabel.reactive.text <~ Property.combineLatest(
            videoPlayer.currentTime,
            Property(initial: 0, then: playerControlView.seekingSlider.reactive.values),
            videoPlayer.duration)
                .producer
                .take(duringLifetimeOf: self)
                .map { [unowned self] currentPlayerTime, seekingSliderPosition, duration -> TimeInterval in
                    if self.playerControlView.isTracking {
                        return Double(seekingSliderPosition) * duration
                    } else {
                        return currentPlayerTime
                    }
                }
                .map(PlayerViewController.stringRepresentation(ofTime:))

        let isBuffering = videoPlayer.status.signal.take(duringLifetimeOf: self).map { $0 == .buffering }
        playerControlView.loadingIndicator.reactive.isAnimating <~ isBuffering
        isBuffering.observeValues { [unowned self] buffering in
            if buffering {
                self.controlsVisible = false
            }
        }

        videoPlayer.isPictureInPictureActive
            .producer
            .take(duringLifetimeOf: self)
            .observe(on: QueueScheduler.main)
            .startWithValues { [unowned self] isPictureInPictureActive in
                self.controlsDisabled = isPictureInPictureActive
                if isPictureInPictureActive {
                    self.isFullscreenActive = false
                }
                UIView.animate(withDuration: 0.5) {
                    self.playerControlView.controlView.alpha = isPictureInPictureActive ? 0 : 1
                }
            }
    }

    private func setupSubviews() {
        let contentView = contentViewController.view!
        contentView.backgroundColor = UIColor.black
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }

        contentView.addSubview(videoView)
        videoView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }

        contentView.addSubview(playerControlView)
        playerControlView.snp.makeConstraints { make in
            make.size.equalTo(videoView)
            make.center.equalTo(videoView)
        }
    }

    private func setupGestureRecognizer() {
        // TODO Also handle touchDragOutside if touchdown originated inside the slider
        playerControlView.seekingSlider.addTarget(self, action: #selector(self.seeked), for: .touchDragInside)
        playerControlView.seekingSlider.addTarget(self, action: #selector(self.seeked), for: .touchDragOutside)
        playerControlView.seekingSlider.addTarget(self, action: #selector(self.seekFinished), for: .touchUpInside)
        playerControlView.seekingSlider.addTarget(self, action: #selector(self.seekFinished), for: .touchUpOutside)
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

    func disableControls() {
        playerControlView.isHidden = true
    }

    func enableControls() {
        playerControlView.isHidden = false
    }

    var isFullscreenActive = false {
        didSet {
            UIView.animate(withDuration: 0.25) {
                self.playerControlView.isFullscreenActive = self.isFullscreenActive
                self.delegate?.playerViewController(self, didChangeFullscreenStatus: self.isFullscreenActive)

                self.refreshControlHideTimer()
            }
        }
    }

    private var idleTimer: Timer?
    private var controlsDisabled = false
    private var controlsVisible: Bool {
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
        if playerControlView.isTracking || videoPlayer.status.value != .playing {
            refreshControlHideTimer()
        } else {
            controlsVisible = false
        }
    }

    @objc func viewTapped(recognizer: UITapGestureRecognizer) {
        if videoPlayer.status.value == .playing, recognizer.numberOfTouches == 1, !controlsVisible {
            let location = recognizer.location(ofTouch: 0, in: playerControlView.playButton)
            let hiddenPlayTouchTolerance = CGFloat(20)

            if playerControlView.playButton.bounds.insetBy(dx: -hiddenPlayTouchTolerance, dy: -hiddenPlayTouchTolerance).contains(location) {
                videoPlayer.pause()
            }
        }

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
            videoPlayer.seek(by: 10)
        } else {
            videoPlayer.seek(by: -10)
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

        alert.reactive.attributedTitle <~ videoPlayer.currentQuality.map { NSAttributedString(string: "Current quality: \($0?.description ?? "--")") }

        let currentQuality = videoPlayer.preferredQuality.value

        let action = UIAlertAction(title: "Automatic", style: .default) { _ in
            self.videoPlayer.preferredQuality.value = nil
        }

        if currentQuality == nil {
            action.setValue(true, forKey: "checked")
        }
        alert.addAction(action)

        // TODO Filter actually available qualities
        StreamQuality.ascendingOrder.reversed().forEach { quality in
            let action = UIAlertAction(title: quality.description, style: .default) { _ in
                self.videoPlayer.preferredQuality.value = quality
            }

            if quality == currentQuality {
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
        // TODO Use AVAssetImageGenerator to generate and show thumbnails for the currently seeked time
        self.refreshControlHideTimer()
    }

    @objc func seekFinished() {
        videoPlayer.seek(toPercentage: Double(playerControlView.seekingSlider.value))
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

public protocol PlayerViewControllerDelegate: class {
    func playerViewController(_ playerViewController: PlayerViewController, didChangeFullscreenStatus: Bool)
}
