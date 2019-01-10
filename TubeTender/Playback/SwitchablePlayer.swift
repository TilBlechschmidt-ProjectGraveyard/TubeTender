//
//  SwitchablePlayer.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 08.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import AVKit
import ReactiveSwift

class SwitchablePlayer: UIView {
    static let shared = SwitchablePlayer()

    private var previousPlaybackPosition: TimeInterval?
    private var previouslyPlaying: Bool?
    private var player: Player {
        willSet {
            previousPlaybackPosition = currentTime.value
            previouslyPlaying = status.value == .playing
            // Remove the old player from existence
            player.stop()
            // TODO Wait with this until the new player has finished loading
            player.drawable.removeFromSuperview()
        }
        didSet {
            setupPlayer()
            previouslyPlaying = nil
            previousPlaybackPosition = nil
        }
    }

    var pictureInPictureController: AVPictureInPictureController?

    let playbackItem = MutableProperty<Video?>(nil)
    let preferredQuality = MutableProperty<StreamQuality>(.hd1080)
    let preferHighFPS = MutableProperty(true)
    let preferHDR = MutableProperty(false)

    private let _currentTime = MutableProperty<TimeInterval>(0)
    private let _duration = MutableProperty<TimeInterval>(0)
    private let _status = MutableProperty<PlayerStatus>(.noMediaLoaded)
    private let _pictureInPictureActive = MutableProperty(false)

    let currentTime: Property<TimeInterval>
    let duration: Property<TimeInterval>
    let status: Property<PlayerStatus>
    let pictureInPictureActive: Property<Bool>

    init(withPlayer player: Player = VLCPlayer()) {
        self.player = player
        self.currentTime = Property(_currentTime)
        self.duration = Property(_duration)
        self.status = Property(_status)
        self.pictureInPictureActive = Property(_pictureInPictureActive)
        super.init(frame: .zero)
        setupPlayer()

        playbackItem.signal.observeValues { _ in self.reloadVideo(restorePlaybackPosition: false) }
        preferredQuality.signal.observeValues { _ in self.reloadVideo() }
        preferHighFPS.signal.observeValues { _ in self.reloadVideo() }
        preferHDR.signal.observeValues { _ in self.reloadVideo() }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPlayer() {
        addSubview(player.drawable)
        player.drawable.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
        }
        reloadVideo()

        _currentTime <~ player.currentTime
        _duration <~ player.duration
        _status <~ player.status
    }

    private func reloadVideo(restorePlaybackPosition: Bool = true) {
        if let video = playbackItem.value {
            let wasPreviouslyPlaying = previouslyPlaying ?? (status.value == .playing)
            let previousPosition = previousPlaybackPosition ?? currentTime.value
            player.stop()

            // TODO Replace take1 with disposing of the previous producer when this function gets called
            // That combined with a auto-refreshing cache could circumvent the lifetime of the streams (e.g. app in bg)
            video.stream(withPreferredQuality: preferredQuality.value,
                         adaptive: player.featureSet.contains(.adaptiveStreaming),
                         preferHighFPS: self.preferHighFPS.value && player.featureSet.contains(.highFps),
                         preferHDR: self.preferHDR.value && player.featureSet.contains(.hdr)
            ).take(first: 1).observe(on: QueueScheduler.main).startWithValues { stream in
                if let videoStream = URL(string: stream.video.url) {
                    self.player.load(url: videoStream)
                }
                if let audioStream = (stream.audio?.url).flatMap({ URL(string: $0) }) {
                    self.player.loadAudio(url: audioStream)
                }

                if wasPreviouslyPlaying || !restorePlaybackPosition {
                    self.player.play()
                }
                if restorePlaybackPosition {
                    self.player.seek(to: previousPosition)
                }
            }
        } else {
            player.stop()
        }
    }

    // MARK: - Playback controls
    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func seek(toPercentage percentage: Double) {
        let target = duration.value * percentage
        player.seek(to: target)
    }

    func seek(by distance: TimeInterval) {
        let target = currentTime.value + distance
        player.seek(to: max(min(target, duration.value - 5), 0))
    }

    func seek(to target: TimeInterval) {
        player.seek(to: target)
    }

    func startPictureInPicture() {
        _pictureInPictureActive.value = true

        let nativePlayer = NativePlayer()
        player = nativePlayer

        pictureInPictureController = AVPictureInPictureController(playerLayer: nativePlayer.playerView.playerLayer)
        pictureInPictureController?.delegate = self

        status.signal.take(while: { $0 != .playing }).observeCompleted {
            self.pictureInPictureController?.startPictureInPicture()
        }
    }

    func stopPictureInPicture() {
        _pictureInPictureActive.value = false
        player = VLCPlayer()
    }
}

extension SwitchablePlayer: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.stopPictureInPicture()
    }
}
