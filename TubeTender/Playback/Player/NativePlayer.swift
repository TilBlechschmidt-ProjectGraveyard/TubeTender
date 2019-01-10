//
//  NativePlayer.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 31.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import AVKit

class AVPlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

// TODO Implement the handling of .playbackFinished
class NativePlayer: NSObject {
    private var _currentTime: MutableProperty<TimeInterval> = MutableProperty(0)
    private var _duration: MutableProperty<TimeInterval> = MutableProperty(0)
    private var _status: MutableProperty<PlayerStatus> = MutableProperty(.noMediaLoaded)

    private(set) var playerView = AVPlayerView()
    private var player: AVPlayer?

    lazy var currentTime: Property<TimeInterval> = Property(_currentTime)
    lazy var duration: Property<TimeInterval> = Property(_duration)
    lazy var status: Property<PlayerStatus> = Property(_status)

    private(set) var drawable: UIView

    override init() {
        drawable = playerView
    }
}

extension NativePlayer: Player {
    var featureSet: PlayerFeatures { return [.hdr, .highFps] }

    func load(url: URL) {
        // Create asset to be played
        let asset = AVAsset(url: url)

        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        let playerItem = AVPlayerItem(asset: asset)

        playerItem.reactive.signal(forKeyPath: #keyPath(AVPlayerItem.status)).observeValues { media in
            self._duration.value = playerItem.duration.seconds
        }

        // Create the player
        player = AVPlayer(playerItem: playerItem)
        playerView.player = player

        // Observe the time
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000),
                                        queue: DispatchQueue.main) { time in
            if let currentTime = self.player?.currentTime() {
                self._currentTime.value = currentTime.seconds
            }
        }

        _status.value = .buffering

        player?.reactive.signal(forKeyPath: #keyPath(AVPlayer.timeControlStatus)).observeValues { _ in
            guard let status = self.player?.timeControlStatus else { return }
            switch status {
            case .paused:
                self._status.value = .paused
            case .waitingToPlayAtSpecifiedRate:
                self._status.value = .buffering
            case .playing:
                self._status.value = .playing
            }
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.pause()
        player = nil
        playerView.player = nil
        _status.value = .noMediaLoaded
    }

    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 1000))
    }
}
