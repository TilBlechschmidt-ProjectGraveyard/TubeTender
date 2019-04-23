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

enum VideoPlayerQueueChangeSet {
    case inserted(at: Int)
    case removed(at: Int)
    case moved(from: Int, to: Int)
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
    private let _videos: MutableProperty<[Video]>
    private let player: AVQueuePlayer
    private let pictureInPictureController: AVPictureInPictureController?
    let playerView: AVPlayerView
    private let commandCenter: CommandCenter

    private var changeSetObserver: Signal<VideoPlayerQueueChangeSet, Never>.Observer!
    private(set) var changeSetSignal: Signal<VideoPlayerQueueChangeSet, Never>!

    let currentIndex: Property<Int?>
    let currentItem: Property<Video?>
    let videos: Property<[Video]>

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

        let videos = MutableProperty<[Video]>([])

        // Initialize public properties with private ones
        currentTime = Property(_currentTime)
        duration = Property(_duration)
        status = Property(_status)
        isPictureInPictureActive = Property(_isPictureInPictureActive)
        currentQuality = Property(_currentQuality)
        currentIndex = Property(_currentIndex)
        self.videos = Property(videos)

        // Initialize queue
        self._videos = videos
        player = AVQueuePlayer(items: [])
        playerView.player = player
        pictureInPictureController = AVPictureInPictureController(playerLayer: playerView.playerLayer)

        currentItem = Property(currentIndex.map { $0.map { videos.value[$0] } })

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

    deinit {
        playerTimeControlStatusObserver?.invalidate()
        currentItemPresentationSizeObserver?.invalidate()
        currentItemStatusObserver?.invalidate()
    }

    private var playerTimeControlStatusObserver: NSKeyValueObservation?
    private var currentItemStatusObserver: NSKeyValueObservation?
    private var currentItemPresentationSizeObserver: NSKeyValueObservation?

    private func setupObservers() {
        // Player related
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: DispatchQueue.main) { time in
            self._currentTime.value = time.seconds
        }

        playerTimeControlStatusObserver = player.observe(\.timeControlStatus, options: []) { [unowned self] player, _ in
            self.updateStatus(from: player)
        }

        preferredQuality.signal.take(duringLifetimeOf: self).observeValues { [unowned self] preferredQuality in
            if let maximumResolution = preferredQuality?.resolution {
                self.player.items().forEach { playerItem in
                    playerItem.preferredMaximumResolution = maximumResolution
                }
            }
        }

        // Command center related
        commandCenter.hasNext <~ currentIndex.combineLatest(with: videos).map { index, videos in
            return index.flatMap { $0 < videos.count - 1 } ?? false
        }
        commandCenter.hasPrevious <~ currentIndex.combineLatest(with: videos).map { index, videos in
            return index.flatMap { $0 > 0 && !videos.isEmpty } ?? (!videos.isEmpty)
        }

        commandCenter.elapsedTime <~ self.currentTime
        commandCenter.duration <~ self.duration

        // Playback related
        currentIndex.combineLatest(with: videos).signal.observeValues { [unowned self] index, videos in
            if let index = index {
                let currentVideo = videos[index]
                let currentItem = self.player.items().first

                self.commandCenter.load(video: currentVideo)

                self.currentItemStatusObserver?.invalidate()
                self.currentItemStatusObserver = currentItem?.observe(\.status, options: []) { [unowned self] playerItem, _ in
                    self.updateStatus(from: playerItem)
                }

                self.currentItemPresentationSizeObserver?.invalidate()
                self.currentItemPresentationSizeObserver = currentItem?.observe(\.presentationSize, options: []) { [unowned self] playerItem, _ in
                    self.updatePresentationSize(from: playerItem)
                }

                if let currentItem = currentItem {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidPlayToEndTime), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
                }
            }
        }
    }

    @objc func playerItemDidPlayToEndTime() {
        changeIndex(by: 1)
    }

    // MARK: - Helpers
    private func createPlayerItem(fromVideo video: Video) -> AVPlayerItem {
        let playerItem = AVPlayerItem(url: video.hlsURL)

        if let maximumResolution = preferredQuality.value?.resolution {
            playerItem.preferredMaximumResolution = maximumResolution
        }

        return playerItem
    }

    private func updatePresentationSize(from playerItem: AVPlayerItem) {
        self._currentQuality.value = StreamQuality.from(videoSize: playerItem.presentationSize)
    }

    private func updateStatus(from playerItem: AVPlayerItem) {
        switch playerItem.status {
        case .readyToPlay:
            self._duration.value = playerItem.duration.seconds
            self.play()
        case .failed:
            self._status.value = .playbackFailed
        default:
            break
        }
    }

    private func updateStatus(from player: AVPlayer) {
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

    func refreshState() {
        // TODO Figure out how many items have been played since we went to sleep.

        updateStatus(from: player)

        if let currentPlayerItem = player.currentItem {
            updateStatus(from: currentPlayerItem)
            updatePresentationSize(from: currentPlayerItem)
        }
    }

    private func changeIndex(to newIndex: Int) {
        if newIndex >= _videos.value.count || newIndex < 0 {
            _currentIndex.value = nil
        } else {
            _currentIndex.value = newIndex
        }
    }

    private func changeIndex(by delta: Int) {
        changeIndex(to: (currentIndex.value ?? (_videos.value.count - 1)) + delta)
    }

    // MARK: - Moving the queue
    func setIndex(to newIndex: Int) {
        let oldIndex = currentIndex.value ?? (videos.value.count - 1)
        let delta = newIndex - oldIndex

        guard delta != 0 else { return }

        _status.value = .buffering

        let currentPlayerItem = player.items().first

        if delta > 0 {
            player.items()[1..<delta].forEach(player.remove)
        } else { // delta < 0
            videos.value[newIndex...oldIndex].reversed().forEach {
                player.insert(createPlayerItem(fromVideo: $0), after: currentPlayerItem)
            }
        }

        if currentPlayerItem != nil {
            player.advanceToNextItem()
        }

        changeIndex(to: newIndex)
    }

    func next() {
        _status.value = .buffering
        player.advanceToNextItem()
        changeIndex(by: 1)
    }

    func previous() {
        // TODO Go to the beginning of the current video if we aren't within the first few seconds.
        if let currentIndex = _currentIndex.value, currentIndex > 0 {
            let currentlyPlayingItem = player.items().first

            _status.value = .buffering

            // Insert the previous item after the currently playing (if applicable)
            let previousItem = createPlayerItem(fromVideo: _videos.value[currentIndex - 1])
            player.insert(previousItem, after: currentlyPlayingItem)

            // If applicable insert the currently playing item after the previous item
            if let currentlyPlayingItem = currentlyPlayingItem {
                player.insert(currentlyPlayingItem, after: previousItem)
            }

            // Update the queue index
            changeIndex(by: -1)
        }
    }

    // MARK: - Manipulating the queue
    private func addVideoToBeginningOfQueue(_ video: Video) -> Int {
        let newIndex = (currentIndex.value + 1) ?? _videos.value.count

        _videos.value.insert(video, at: newIndex)
        player.insert(createPlayerItem(fromVideo: video), after: player.items().first)
        return newIndex
    }

    private func addVideoToEndOfQueue(_ video: Video) -> Int {
        let newIndex = _videos.value.count

        _videos.value.insert(video, at: newIndex)
        player.insert(createPlayerItem(fromVideo: video), after: nil)
        return newIndex
    }

    func remove(from index: Int) {
        // TODO This function should only work for index > currentIndex. Add guard
        _videos.value.remove(at: index)

        if let currentIndex = currentIndex.value {
            if index == currentIndex {
                player.advanceToNextItem()
            } else if index > currentIndex {
                let playerIndexToDelete = index - currentIndex
                player.remove(player.items()[playerIndexToDelete])
            }

            if currentIndex >= _videos.value.count {
                _currentIndex.value = nil
            }
        }

        changeSetObserver.send(value: .removed(at: index))
    }

    func playNow(_ video: Video) {
        let newIndex = addVideoToBeginningOfQueue(video)
        changeSetObserver.send(value: .inserted(at: newIndex))
        if currentIndex.value == nil {
            _status.value = .buffering
            changeIndex(to: newIndex)
            changeSetObserver.send(value: .inserted(at: newIndex))
        } else {
            changeSetObserver.send(value: .inserted(at: newIndex))
            next()
        }
    }

    func playNext(_ video: Video) {
        let newIndex = addVideoToBeginningOfQueue(video)
        if currentIndex.value == nil {
            changeIndex(to: newIndex)
        }

        changeSetObserver.send(value: .inserted(at: newIndex))
    }

    func playLater(_ video: Video) {
        let newIndex = addVideoToEndOfQueue(video)
        if currentIndex.value == nil {
            changeIndex(to: newIndex)
        }

        changeSetObserver.send(value: .inserted(at: newIndex))
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
        DispatchQueue.main.async {
            self.pictureInPictureController?.startPictureInPicture()
        }
    }

    func stopPictureInPicture() {
        DispatchQueue.main.async {
            self.pictureInPictureController?.stopPictureInPicture()
        }
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
