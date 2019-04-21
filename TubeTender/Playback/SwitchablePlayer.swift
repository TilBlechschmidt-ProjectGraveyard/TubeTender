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
    private var player: NativePlayer { //Player {
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

    private var pictureInPictureController: AVPictureInPictureController?

    let playbackItem = MutableProperty<Video?>(nil)

    private let _currentTime = MutableProperty<TimeInterval>(0)
    private let _duration = MutableProperty<TimeInterval>(0)
    private let _status = MutableProperty<PlayerStatus>(.noMediaLoaded)
    private let _pictureInPictureActive = MutableProperty(false)
    private let _currentQuality = MutableProperty<StreamQuality?>(nil)

    let currentTime: Property<TimeInterval>
    let duration: Property<TimeInterval>
    let status: Property<PlayerStatus>
    let pictureInPictureActive: Property<Bool>
    let currentQuality: Property<StreamQuality?>
    let preferredQuality = MutableProperty<StreamQuality?>(nil)

    init(withPlayer player: NativePlayer = NativePlayer()) {
        self.player = player
        self.currentTime = Property(_currentTime)
        self.duration = Property(_duration)
        self.status = Property(_status)
        self.pictureInPictureActive = Property(_pictureInPictureActive)
        self.currentQuality = Property(_currentQuality)
        super.init(frame: .zero)
        setupPlayer()

        playbackItem.signal.observeValues { [unowned self] _ in self.reloadVideo(restorePlaybackPosition: false) }

        Settings.subscribe(setting: .DefaultQuality, onChange: { [unowned self] _ in self.reloadVideo() })
        Settings.subscribe(setting: .MobileQuality, onChange: { [unowned self] _ in self.reloadVideo() })

        pictureInPictureController = AVPictureInPictureController(playerLayer: player.playerView.playerLayer)
        pictureInPictureController?.delegate = self
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
        _status <~ player.status
        _currentQuality <~ player.currentQuality

        player.preferredQuality <~ preferredQuality
    }

    var videoBinding: Disposable?

    private func reloadVideo(restorePlaybackPosition: Bool = true) {
        if let video = playbackItem.value {

            videoBinding?.dispose()
            videoBinding = _duration <~ video.duration.filterMap { $0.value }

            let previouslyPlaying = status.value == .playing || status.value == .noMediaLoaded

            if let url = URL(string: "http://localhost:\(Constants.hlsServerPort)/\(video.id).m3u8") {
                self.player.load(url: url)
            }

            // Autostart playback once the media has loaded
            if previouslyPlaying {
                self.status.signal.filter({ $0 == .readyToPlay }).take(first: 1).observeCompleted {
                    if self.status.value != .playing {
                        DispatchQueue.global().async {
                            self.player.play()
                        }
                    }
                }
            }

            // TODO Restore playback position
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
        pictureInPictureController?.startPictureInPicture()
    }

    func stopPictureInPicture() {
        pictureInPictureController?.stopPictureInPicture()
    }
}

extension SwitchablePlayer: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        _pictureInPictureActive.value = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        _pictureInPictureActive.value = false
    }
}
