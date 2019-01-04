//
//  VLC.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 31.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import ReactiveSwift

class VLCPlayer {
    private var vlcMediaPlayer: VLCMediaPlayer = VLCMediaPlayer()
    private var previousState: VLCMediaPlayerState = .stopped

    private var _currentTime: MutableProperty<TimeInterval> = MutableProperty(0)
    private var _duration: MutableProperty<TimeInterval> = MutableProperty(0)
    private var _status: MutableProperty<PlayerStatus> = MutableProperty(.noMediaLoaded)

    lazy var currentTime: Property<TimeInterval> = Property(_currentTime)
    lazy var duration: Property<TimeInterval> = Property(_duration)
    lazy var status: Property<PlayerStatus> = Property(_status)

    private(set) var drawable = UIView() { didSet { vlcMediaPlayer.drawable = drawable } }

    init() {
        vlcMediaPlayer.delegate = self
    }
}

extension VLCPlayer: Player {
    func load(url: URL) {
        vlcMediaPlayer.media = VLCMedia(url: url)
        // TODO Set the duration and current time once loaded
    }

    func loadAudio(url: URL) {
        vlcMediaPlayer.addPlaybackSlave(url, type: .audio, enforce: true)
    }

    func play() {
        vlcMediaPlayer.play()
        // TODO Check if buffering
        _status.value = .playing
    }

    func pause() {
        vlcMediaPlayer.pause()
        _status.value = .paused
    }

    func stop() {
        vlcMediaPlayer.stop()
        _status.value = .noMediaLoaded
        _currentTime.value = 0
        _duration.value = 0
    }

    func seek(to time: TimeInterval) {
        vlcMediaPlayer.time = VLCTime(int: Int32(time * 1000))
    }
}

extension VLCPlayer: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged() {
        _currentTime.value = Double(vlcMediaPlayer.time.intValue) / 1000
    }

    func mediaPlayerStateChanged() {
        let currentState: VLCMediaPlayerState  = vlcMediaPlayer.state;

        // TODO Take a look at isPlaying and willPlay
        // TODO Manage buffering (which is currently not handled at all)

        // Handle state transitions for states that only make sense when combined
        if previousState == .esAdded && currentState == .buffering {
            vlcMediaPlayer.media.flatMap { self._duration.value = Double($0.length.intValue) / 1000 }
        }

        // Handle specific states that can appear by themselves
        switch(currentState) {
        case .ended:
            // TODO: The video feed ends a few seconds short. Figure out why
            _status.value = .noMediaLoaded
        case .stopped:
            _status.value = .noMediaLoaded
        case .paused:
            _status.value = .paused
        case .playing:
            _status.value = .playing
        default:
            break;
        }

        previousState = currentState
    }
}
