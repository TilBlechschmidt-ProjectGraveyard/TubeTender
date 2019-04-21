//
//  VLC.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 31.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import ReactiveSwift

class VLCPlayer: NSObject {
    private var vlcMediaPlayer: VLCMediaPlayer!
    private var previousState: VLCMediaPlayerState = .stopped

    private let _currentTime: MutableProperty<TimeInterval> = MutableProperty(0)
    private let _duration: MutableProperty<TimeInterval> = MutableProperty(0)
    private let _status: MutableProperty<PlayerStatus> = MutableProperty(.noMediaLoaded)

    let currentTime: Property<TimeInterval>
    let duration: Property<TimeInterval>
    let status: Property<PlayerStatus>

    let drawable = UIView()

    override init() {
        currentTime = Property(_currentTime)
        duration = Property(_duration)
        status = Property(_status)
        super.init()
        replaceMediaPlayer()
    }

    func replaceMediaPlayer() {
        vlcMediaPlayer = VLCMediaPlayer()
        vlcMediaPlayer.delegate = self
        vlcMediaPlayer.drawable = drawable
        previousState = .stopped
        _status.value = .noMediaLoaded
        _duration.value = 0
        _currentTime.value = 0
    }
}

extension VLCPlayer: Player {
    var featureSet: PlayerFeatures { return .all }

    func load(url: URL) {
        stop()
        vlcMediaPlayer.media = VLCMedia(url: url)
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
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        _currentTime.value = Double(vlcMediaPlayer.time.intValue) / 1000
    }

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
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
            _status.value = .playbackFinished
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
