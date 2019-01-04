//
//  NativePlayer.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 31.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import AVKit

class NativePlayer: NSObject {
    private var _currentTime: MutableProperty<TimeInterval> = MutableProperty(0)
    private var _duration: MutableProperty<TimeInterval> = MutableProperty(0)
    private var _status: MutableProperty<PlayerStatus> = MutableProperty(.noMediaLoaded)

    private var playerView = AVPlayerView()
    private var player: AVPlayer?

    lazy var currentTime: Property<TimeInterval> = Property(_currentTime)
    lazy var duration: Property<TimeInterval> = Property(_duration)
    lazy var status: Property<PlayerStatus> = Property(_status)

    private(set) var drawable: UIView

    override init() {
        drawable = playerView
    }

    deinit {
        player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem))
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)

        print("\(keyPath): \(change?[.newKey])")

        // TODO Check if this works
        if keyPath == #keyPath(AVPlayer.currentItem), change?[.oldKey] == nil, let media = change?[.newKey] as? AVPlayerItem {
            print(media.duration.seconds)
            self._duration.value = media.duration.seconds
        }
    }
}

extension NativePlayer: Player {
    func load(url: URL) {
        player = AVPlayer(url: url)
        playerView.player = player

        // Observe the time
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000),
                                        queue: DispatchQueue.main) { time in
            if let currentTime = self.player?.currentTime() {
                self._currentTime.value = currentTime.seconds
            }
        }

        // TODO Observe the playback state (ended, buffering)
        // TODO Set _duration once its available (available here: player?.currentItem?.duration)
        player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem), options: [.old, .new], context: nil)
    }

    func loadAudio(url: URL) {
        fatalError("Unimplemented (loadAudio @ NativePlayer)")
    }

    func play() {
        player?.play()
        // TODO Check if buffering
        _status.value = .playing
    }

    func pause() {
        player?.pause()
        _status.value = .paused
    }

    func stop() {
        _status.value = .noMediaLoaded
        player?.pause()
        player = nil
        playerView.player = nil
    }

    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 1000))
    }
}
