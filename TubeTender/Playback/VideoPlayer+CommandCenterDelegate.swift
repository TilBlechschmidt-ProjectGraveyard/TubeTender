//
//  VideoPlayer+CommandCenterDelegate.swift
//  TubeTender
//
//  Created by Noah Peeters on 23.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import MediaPlayer

extension VideoPlayer: CommandCenterDelegate {
    func commandCenter(_ commandCenter: CommandCenter, didReceiveCommand command: CommandCenterAction) -> MPRemoteCommandHandlerStatus {
        switch command {
        case .play:
            self.play()
        case .pause:
            self.pause()
        case .seek(let target):
            self.seek(to: target)
        case .next:
            self.next()
        case .previous:
            self.previous()
        }

        return .success
    }
}
