////
////  PlaybackQueue.swift
////  TubeTender
////
////  Created by Til Blechschmidt on 09.01.19.
////  Copyright © 2019 Til Blechschmidt. All rights reserved.
////
//
//import UIKit
//import ReactiveSwift
//import Result
//import MediaPlayer
//
//enum PlaybackQueueChangeSet {
//    case inserted(atIndex: Int)
//    case removed(atIndex: Int)
//    case moved(fromIndex: Int, toIndex: Int)
//}
//
//class PlaybackQueue {
//    static let `default` = PlaybackQueue(player: VideoPlayer(), commandCenter: CommandCenter.shared)
//
//    let player: VideoPlayer
//    let commandCenter: CommandCenter
//
//    private let _videos: MutableProperty<[Video]>
//    private let _currentIndex = MutableProperty<Int?>(nil)
//    private var changeSetObserver: Signal<PlaybackQueueChangeSet, NoError>.Observer!
//
//    let videos: Property<[Video]>
//    let currentIndex: Property<Int?>
//    private(set) var changeSetSignal: Signal<PlaybackQueueChangeSet, NoError>!
//
//    // Queue: Latest item will be played next
//    let queue: Property<ArraySlice<Video>>
//    let currentItem: Property<Video?>
//    // History: Latest item has been played most recently
//    let history: Property<ArraySlice<Video>>
//
//    init(player: VideoPlayer, commandCenter: CommandCenter) {
//        self.player = player
//        self.commandCenter = commandCenter
//
//        let videos = MutableProperty<[Video]>([])
//        self._videos = videos
//        self.videos = Property(videos)
//        self.currentIndex = Property(_currentIndex)
//
//        self.currentItem = Property(currentIndex.map { $0.map({ videos.value[$0] }) })
//        self.queue = Property(currentIndex.map { videos.value[(($0 + 1) ?? videos.value.count)...] })
//        self.history = Property(currentIndex.map { videos.value[..<($0 ?? videos.value.count)] })
//
//        self.changeSetSignal = Signal { observer, lifetime in
//            self.changeSetObserver = observer
//        }
//
//        // TODO Don't bind the elapsed time but instead just set it when the status changes.
//        commandCenter.elapsedTime <~ self.player.currentTime
//        commandCenter.duration <~ self.player.duration
//
//        commandCenter.hasNext <~ self.currentIndex.map { index in
//            return index.flatMap({ $0 < videos.value.count - 1  }) ?? false
//        }
//        commandCenter.hasPrevious <~ self.currentIndex.map { index in
//            return index.flatMap({ $0 > 0 && videos.value.count > 0 }) ?? (videos.value.count > 0)
//        }
//
//        commandCenter.delegate = self
//
//        player.status.signal.observeValues { status in
//            if status == .playbackFinished {
//                print("playing next video in 2 seconds")
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    self.next()
//                }
//            }
//        }
//    }
//
//    func changeIndex(by delta: Int) {
//        var newIndex = currentIndex.value ?? (videos.value.count - 1)
//
//        newIndex += delta
//
//        if newIndex >= videos.value.count || newIndex < 0 {
//            _currentIndex.value = nil
//        } else {
//            _currentIndex.value = newIndex
//        }
//
//        if player.playbackItem.value != currentItem.value {
//            player.playbackItem.value = currentItem.value
//            if let video = currentItem.value {
//                commandCenter.load(video: video)
//            }
//        }
//    }
//
//    func next() {
//        changeIndex(by: 1)
//    }
//
//    func previous() {
//        changeIndex(by: currentIndex.value == nil ? 0 : -1)
//    }
//
//    func playNow(_ video: Video) {
//        let playing = currentItem.value != nil
//        playNext(video)
//        changeIndex(by: playing ? 1 : 0)
//    }
//
//    func playNext(_ video: Video) {
//        let insertionIndex = (currentIndex.value + 1) ?? videos.value.count
//        _videos.value.insert(video, at: insertionIndex)
//        changeSetObserver.send(value: PlaybackQueueChangeSet.inserted(atIndex: insertionIndex))
//        changeIndex(by: 0)
//    }
//
//    func playLater(_ video: Video) {
//        _videos.value.append(video)
//        changeSetObserver.send(value: PlaybackQueueChangeSet.inserted(atIndex: videos.value.count - 1))
//        changeIndex(by: 0)
//    }
//}
//
//extension PlaybackQueue: CommandCenterDelegate {
//    func commandCenter(_ commandCenter: CommandCenter, didReceiveCommand command: CommandCenterAction) -> MPRemoteCommandHandlerStatus {
//        switch command {
//        case .play:
//            self.player.play()
//        case .pause:
//            self.player.pause()
//        case .seek(let target):
//            self.player.seek(to: target)
//        case .next:
//            self.next()
//        case .previous:
//            self.previous()
//        }
//
//        return .success
//    }
//}
//
//fileprivate func +(lhs: Int?, rhs: Int) -> Int? {
//    return lhs.map { $0 + rhs }
//}
