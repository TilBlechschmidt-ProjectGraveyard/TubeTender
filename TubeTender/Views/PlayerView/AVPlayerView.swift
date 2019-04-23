//
//  AVPlayerView.swift
//  TubeTender
//
//  Created by Noah Peeters on 23.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import AVKit
import UIKit

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
        //swiftlint:disable:next force_cast
        return layer as! AVPlayerLayer
    }

    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
