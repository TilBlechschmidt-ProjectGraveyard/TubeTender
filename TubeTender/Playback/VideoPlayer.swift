//
//  VideoPlayer.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 22.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import AVKit
import MediaPlayer
import ReactiveSwift

typealias QueueEntry = (video: Video, playerItem: AVPlayerItem)

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

enum VideoPlayerQueueChangeSet {
    case inserted(atIndex: Int)
    case removed(atIndex: Int)
    case moved(fromIndex: Int, toIndex: Int)
}

enum PlayerStatus {
    case noMediaLoaded
    case playbackFailed
    case playbackFinished

    case readyToPlay

    case playing
    case buffering
    case paused
}

class VideoPlayer: NSObject {
    static let shared = VideoPlayer()

    // MARK: - Player & Item Queue
    private let _currentIndex = MutableProperty<Int?>(nil)
    private let videos: MutableProperty<[QueueEntry]>
    private let player: AVQueuePlayer
    private let pictureInPictureController: AVPictureInPictureController?
    let playerView: AVPlayerView
    private let commandCenter: CommandCenter

    private var changeSetObserver: Signal<VideoPlayerQueueChangeSet, Never>.Observer!
    private(set) var changeSetSignal: Signal<VideoPlayerQueueChangeSet, Never>!

    // Queue: Latest item will be played next
    let currentIndex: Property<Int?>
    let queue: Property<[Video]>
    let currentItem: Property<Video?>
    // History: Latest item has been played most recently
    let history: Property<[Video]>

    // MARK: - Playback state
    private let _currentTime = MutableProperty<TimeInterval>(0)
    private let _duration = MutableProperty<TimeInterval>(0)
    private let _status = MutableProperty<PlayerStatus>(.noMediaLoaded)
    private let _isPictureInPictureActive = MutableProperty(false)
    private let _currentQuality = MutableProperty<StreamQuality?>(nil)

    let currentTime: Property<TimeInterval>
    let duration: Property<TimeInterval>
    let status: Property<PlayerStatus>

    let isPictureInPictureActive: Property<Bool>

    let currentQuality: Property<StreamQuality?>
    let preferredQuality = MutableProperty<StreamQuality?>(nil)

    // MARK: - Initializers
    private init(commandCenter: CommandCenter = CommandCenter.shared) {
        playerView = AVPlayerView()

        // Initialize public properties with private ones
        currentTime = Property(_currentTime)
        duration = Property(_duration)
        status = Property(_status)
        isPictureInPictureActive = Property(_isPictureInPictureActive)
        currentQuality = Property(_currentQuality)
        currentIndex = Property(_currentIndex)

        // Initialize queue
        let videos = MutableProperty<[QueueEntry]>([])
        self.videos = videos
        player = AVQueuePlayer(items: videos.value.map { $0.playerItem })
        playerView.player = player
        pictureInPictureController = AVPictureInPictureController(playerLayer: playerView.playerLayer)

        currentItem = Property(currentIndex.map { $0.map { videos.value[$0] }.map { $0.video } })
        queue = Property(currentIndex.map { videos.value[(($0 + 1) ?? videos.value.count)...].map { $0.video } })
        history = Property(currentIndex.map { videos.value[..<($0 ?? videos.value.count)].map { $0.video } })

        // Other properties
        self.commandCenter = commandCenter

        // Initialize superclass
        super.init()

        // Setup signals
        changeSetSignal = Signal { observer, _ in
            self.changeSetObserver = observer
        }

        // Set delegates
        commandCenter.delegate = self
        pictureInPictureController?.delegate = self

        // Create internal bindings
        setupObservers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupObservers() {
        // Player related
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: DispatchQueue.main) { time in
            self._currentTime.value = time.seconds
        }

        player.reactive.signal(forKeyPath: #keyPath(AVPlayer.timeControlStatus)).observeValues { [unowned self] _ in
            switch self.player.timeControlStatus {
            case .paused:
                self._status.value = .paused
            case .waitingToPlayAtSpecifiedRate:
                self._status.value = .buffering
            case .playing:
                self._status.value = .playing
            @unknown default:
                fatalError("Unexpected timeControlStatus")
            }
        }

        preferredQuality.signal.take(duringLifetimeOf: self).observeValues { [unowned self] preferredQuality in
            if let maximumResolution = preferredQuality?.resolution {
                self.videos.value.forEach { queueItem in
                    queueItem.playerItem.preferredMaximumResolution = maximumResolution
                }
            }
        }

        // Playback related
        currentIndex.signal.observeValues { [unowned self] currentIndex in
            if let index = currentIndex {
                self.load(videoAtQueueIndex: index)
            }
        }

        // Command center related
        commandCenter.hasNext <~ self.currentIndex.map { index in
            return index.flatMap { $0 < self.videos.value.count - 1 } ?? false
        }
        commandCenter.hasPrevious <~ self.currentIndex.map { index in
            return index.flatMap { $0 > 0 && !self.videos.value.isEmpty } ?? !self.videos.value.isEmpty
        }

        commandCenter.elapsedTime <~ self.currentTime
        commandCenter.duration <~ self.duration
    }

    // MARK: - Helpers
    private func createQueueItem(fromVideo video: Video) -> QueueEntry {
        let queueItem = (video: video, playerItem: AVPlayerItem(url: video.hlsURL))

        if let maximumResolution = preferredQuality.value?.resolution {
            queueItem.playerItem.preferredMaximumResolution = maximumResolution
        }

        return queueItem
    }

    private var currentItemStatusObserver: NSKeyValueObservation?
    private var currentItemPresentationSizeObserver: NSKeyValueObservation?

    private func load(videoAtQueueIndex index: Int) {
        let futureVideos = videos.value[index...]

        player.removeAllItems()

        let initialPreviousPlayerItem: AVPlayerItem? = nil
        _ = futureVideos.reduce(initialPreviousPlayerItem) { (previousPlayerItem, video) in
            player.insert(video.playerItem, after: previousPlayerItem)
            return video.playerItem
        }

        _status.value = .buffering

        currentItemStatusObserver?.invalidate()
        currentItemStatusObserver = futureVideos.first?.playerItem.observe(\.status, options: []) { [unowned self] playerItem, _ in
            switch playerItem.status {
            case .readyToPlay:
                self._duration.value = playerItem.duration.seconds
                self.play()
            case .failed:
                // TODO Show this in the UI
                break
            default:
                break
            }
        }

        currentItemPresentationSizeObserver?.invalidate()
        currentItemPresentationSizeObserver = futureVideos.first?.playerItem.observe(\.presentationSize, options: []) { [unowned self] playerItem, _ in
            self._currentQuality.value = StreamQuality.from(videoSize: playerItem.presentationSize)
        }
    }

    // MARK: - Queue manipulation
    func changeIndex(to newIndex: Int) {
        if newIndex >= videos.value.count || newIndex < 0 {
            _currentIndex.value = nil
        } else {
            _currentIndex.value = newIndex
        }

        if let video = currentItem.value {
            commandCenter.load(video: video) // TODO Do this with a binding to currentItem
            load(videoAtQueueIndex: newIndex)
        }
    }

    func changeIndex(by delta: Int) {
        changeIndex(to: currentIndex.value ?? (videos.value.count - 1) + delta)
    }

    func next() {
        changeIndex(by: 1)
    }

    func previous() {
        changeIndex(by: currentIndex.value == nil ? 0 : -1)
    }

    func playNow(_ video: Video) {
        let playing = currentItem.value != nil
        playNext(video)
        changeIndex(by: playing ? 1 : 0)
    }

    func playNext(_ video: Video) {
        let queueItem = createQueueItem(fromVideo: video)
        let insertionIndex = (currentIndex.value + 1) ?? videos.value.count
        videos.value.insert(queueItem, at: insertionIndex)
        changeSetObserver.send(value: VideoPlayerQueueChangeSet.inserted(atIndex: insertionIndex))
        changeIndex(by: 0)
    }

    func playLater(_ video: Video) {
        let queueItem = createQueueItem(fromVideo: video)
        videos.value.append(queueItem)
        changeSetObserver.send(value: VideoPlayerQueueChangeSet.inserted(atIndex: videos.value.count - 1))
        changeIndex(by: 0)
    }

    // MARK: - Playback manipulation
    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func seek(toPercentage percentage: Double) {
        let target = duration.value * percentage
        seek(to: target)
    }

    func seek(by distance: TimeInterval) {
        let target = currentTime.value + distance
        seek(to: max(min(target, duration.value - 5), 0))
    }

    func seek(to target: TimeInterval) {
        player.seek(to: CMTime(seconds: target, preferredTimescale: 1000))
    }

    func startPictureInPicture() {
        pictureInPictureController?.startPictureInPicture()
    }

    func stopPictureInPicture() {
        pictureInPictureController?.stopPictureInPicture()
    }
}

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

extension VideoPlayer: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        _isPictureInPictureActive.value = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        _isPictureInPictureActive.value = false
    }
}

extension Int {
    fileprivate static func + (lhs: Int?, rhs: Int) -> Int? {
        return lhs.map { $0 + rhs }
    }
}
