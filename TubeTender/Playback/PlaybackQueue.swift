//
//  PlaybackQueue.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import ReactiveSwift

class PlaybackQueue {
    static let `default` = PlaybackQueue(player: SwitchablePlayer.shared)

    let player: SwitchablePlayer

    private let videos: MutableProperty<[Video]>
    private let currentIndex = MutableProperty<Int?>(nil)

    // Queue: Latest item will be played next
    let queue: Property<ArraySlice<Video>>
    let currentItem: Property<Video?>
    // History: Latest item has been played most recently
    let history: Property<ArraySlice<Video>>

    init(player: SwitchablePlayer) {
        self.player = player

        let videos = MutableProperty<[Video]>([])
        self.videos = videos

        self.currentItem = Property(currentIndex.map { $0.map({ videos.value[$0] }) })
        self.queue = Property(currentIndex.map { videos.value[(($0 + 1) ?? videos.value.count)...] })
        self.history = Property(currentIndex.map { videos.value[..<($0 ?? videos.value.count)] })

        queue.signal.observeValues { q in
            print(Array(q).map { $0.id })
        }
    }

    func changeIndex(by delta: Int) {
        var newIndex = currentIndex.value ?? (videos.value.count - 1)

        newIndex += delta

        if newIndex >= videos.value.count || newIndex < 0 {
            currentIndex.value = nil
        } else {
            currentIndex.value = newIndex
        }

        if player.playbackItem.value != currentItem.value {
            player.playbackItem.value = currentItem.value
        }
    }

    func next() {
        changeIndex(by: 1)
    }

    func previous() {
        changeIndex(by: -1)
    }

    func playNow(_ video: Video) {
        let playing = currentItem.value != nil
        playNext(video)
        changeIndex(by: playing ? 1 : 0)
    }

    func playNext(_ video: Video) {
        videos.value.insert(video, at: (currentIndex.value + 1) ?? videos.value.count)
        changeIndex(by: 0)
    }

    func playLater(_ video: Video) {
        videos.value.append(video)
        changeIndex(by: 0)
    }
}

fileprivate func +(lhs: Int?, rhs: Int) -> Int? {
    return lhs.map { $0 + rhs }
}
