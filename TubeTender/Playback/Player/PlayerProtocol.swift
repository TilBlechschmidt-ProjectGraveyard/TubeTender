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
    case playbackFinished

    case readyToPlay

    case playing
    case buffering
    case paused
}

struct PlayerFeatures: OptionSet {
    let rawValue: Int

    static let highFps = PlayerFeatures(rawValue: 1 << 0)
    static let hdr = PlayerFeatures(rawValue: 1 << 1)
    static let adaptiveStreaming = PlayerFeatures(rawValue: 1 << 2)

    static let all: PlayerFeatures = [.highFps, .hdr, .adaptiveStreaming]
}

protocol Player: class {
    // Feature support
    var featureSet: PlayerFeatures { get }

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

extension Player {
    func loadAudio(url: URL) {
        fatalError("Unimplemented loadAudio @ Player")
    }
}
