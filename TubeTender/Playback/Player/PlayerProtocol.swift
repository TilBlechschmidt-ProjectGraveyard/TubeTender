//
//  PlayerProtocol.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 31.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import ReactiveSwift

enum PlayerStatus {
    case noMediaLoaded
    case playbackFailed

    case playing
    case buffering
    case paused
}

protocol Player: class {
    // Drawing surface
    var drawable: UIView { get }

    // State
    var currentTime: Property<TimeInterval> { get }
    var duration: Property<TimeInterval> { get }
    var status: Property<PlayerStatus> { get }

    // Media control
    func load(url: URL)
    func loadAudio(url: URL)

    // Playback control
    func play()
    func pause()
    func stop()
    func seek(to: TimeInterval)
}
