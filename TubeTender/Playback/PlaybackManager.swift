//
//  PlaybackManager.swift
//  Pivo
//
//  Created by Til Blechschmidt on 05.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation
import AVKit
import ReactiveSwift
import MediaPlayer

typealias VideoID = String

struct PlayingItem {
    let id: VideoID
    let streamManager: VideoStreamManager
}

enum PlaybackManagerError: Error {
    case videoInfoAPIError(error: VideoStreamAPIError)
    case emptyQueue
    case pictureInPictureUnsupported
}

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
        return layer as! AVPlayerLayer
    }

    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

protocol PlaybackManagerDelegate: class {
    // MARK: Media change
    func playbackManagerWillLoadMedia(_ playbackManager: PlaybackManager, withID: VideoID)
    func playbackManagerDidLoadMedia(_ playbackManager: PlaybackManager, withDuration: Int32)
    func playbackManagerDidEmptyQueue(_ playbackManager: PlaybackManager)

    // MARK: Playback
    func playbackManagerDidStartPlayback(_ playbackManager: PlaybackManager)
    func playbackManagerDidStopPlayback(_ playbackManager: PlaybackManager)
    func playbackManager(_ playbackManager: PlaybackManager, didChangeTime: Int32)
    func playbackManagerDidFinishPlayback(_ playbackManager: PlaybackManager)

    // MARK: Picture in Picture
    func playbackManagerWillStartPictureInPicture(_ playbackManager: PlaybackManager)
    func playbackManagerWillStopPictureInPicture(_ playbackManager: PlaybackManager)
}

class PlaybackManager: NSObject {
    static let shared = PlaybackManager()

    weak var delegate: PlaybackManagerDelegate?

    // MARK: - Stream preferences
    var preferHDR: Bool { didSet { updateSelectedSource() } }
    var preferHighFPS: Bool { didSet { updateSelectedSource() } }
    var preferQuality: StreamQuality? { didSet { updateSelectedSource() } }

    // MARK: - Queue & Current item
    private var playbackQueue: Queue<VideoID> = Queue()
    private var playedStack: [VideoID] = []

    private(set) var currentlyPlaying: PlayingItem? { didSet { updateSelectedSource() } }
    private var selectedSource: StreamSet? { didSet { updatePlayer() } }

    // MARK: - Players
    private var previousState: VLCMediaPlayerState = .stopped
    private var vlcMediaPlayer: VLCMediaPlayer = VLCMediaPlayer()
    var drawable: UIView? {
        didSet {
            vlcMediaPlayer.drawable = drawable
        }
    }

    // MARK: - Initializers
    override init() {
        preferHDR = false
        preferHighFPS = false
        super.init()

        vlcMediaPlayer.delegate = self
    }

    // MARK: - Queue manipulation
    func queueIsEmpty() -> Bool {
        return playbackQueue.isEmpty
    }

    func playNow(videoID: VideoID) -> SignalProducer<(), PlaybackManagerError> {
        playbackQueue.insert(videoID, at: 0)
        return next()
    }

    func enqueue(videoID: VideoID) {
        playbackQueue.enqueue(videoID)
    }

    func remove(queueIndex: Int) {
        playbackQueue.list.remove(at: queueIndex)
    }

    func next() -> SignalProducer<(), PlaybackManagerError> {
        // TODO This will inevitably break when called while PiP is active.
        vlcMediaPlayer.stop()

        // Add the current item to the list of played items
        if let currentlyPlaying = currentlyPlaying {
            playedStack.append(currentlyPlaying.id)
        }

        // Fetch the next video's stream manager
        if let nextVideoID = playbackQueue.dequeue() {
            delegate?.playbackManagerWillLoadMedia(self, withID: nextVideoID)

            return VideoStreamAPI.shared.streamManager(forVideoID: nextVideoID)
                .mapError { .videoInfoAPIError(error: $0) }
                .map { streamManager in
                    self.currentlyPlaying = PlayingItem(id: nextVideoID, streamManager: streamManager)
                }
        } else {
            return SignalProducer(error: .emptyQueue)
        }
    }

    // MARK: - Playback control
    @objc func play() {
        if isPictureInPictureActive {
            nativeMediaPlayer?.play()
        } else {
            vlcMediaPlayer.play()
        }

        delegate?.playbackManagerDidStartPlayback(self)
    }

    @objc func pause() {
        if isPictureInPictureActive {
            nativeMediaPlayer?.pause()
        } else {
            vlcMediaPlayer.pause()
        }

        delegate?.playbackManagerDidStopPlayback(self)
    }

    func stop() {
        if isPictureInPictureActive {
            nativeMediaPlayer?.pause()
        } else {
            vlcMediaPlayer.stop()
        }

        delegate?.playbackManagerDidStopPlayback(self)
    }

    func jumpForward(by jumpSize: Int32 = 10) {
        if isPictureInPictureActive {
            seekPiP(by: Double(jumpSize))
        } else {
            vlcMediaPlayer.jumpForward(jumpSize)
        }
    }

    func jumpBackwards(by jumpSize: Int32 = 10) {
        if isPictureInPictureActive {
            seekPiP(by: Double(-jumpSize))
        } else {
            vlcMediaPlayer.jumpBackward(jumpSize)
        }
    }

    func seek(to position: Double) {
        if isPictureInPictureActive {
            // TODO Implement or forbid by throwing
        } else {
            let duration = vlcMediaPlayer.media.length.intValue
            let timeIndex = Int32(round(position * Double(duration)))
            vlcMediaPlayer.time = VLCTime(int: timeIndex)
        }
    }

    private func seekPiP(by distance: Double) {
        guard let nativeMediaPlayer = nativeMediaPlayer else { return }
        let currentTime = nativeMediaPlayer.currentTime()
        nativeMediaPlayer.seek(
            to: CMTime(seconds: currentTime.seconds + distance, preferredTimescale: currentTime.timescale)
        )
    }

    // MARK: - Picture in picture
    private var nativeMediaPlayer: AVPlayer?
    private var playerView: AVPlayerView = AVPlayerView()
    private var pipController: AVPictureInPictureController?
    private var pipObserver: Any?

    var isPictureInPictureActive: Bool {
        return pipController?.isPictureInPictureActive ?? false
    }

    func startPictureInPicture() throws {
        if !AVPictureInPictureController.isPictureInPictureSupported() {
            throw PlaybackManagerError.pictureInPictureUnsupported
        }

        // TODO Return a SignalSource
        // Fetch the non-adaptive source
        if let currentlyPlaying = currentlyPlaying {
            let quality = preferQuality ?? .hd720
            let source = try? currentlyPlaying.streamManager.stream(withPreferredQuality: quality,
                                                                    adaptive: false,
                                                                    preferHighFPS: preferHighFPS,
                                                                    preferHDR: preferHDR)

            guard let sourceURLString = source?.video.url, let sourceURL = URL(string: sourceURLString) else {
                return
            }

            pause()

            // Create the player and store it
            let player = AVPlayer(url: sourceURL)
            nativeMediaPlayer = player

            // Seek to the correct time
            let currentTime = CMTime(seconds: Double(vlcMediaPlayer.time.intValue) / 1000, preferredTimescale: 1000)
            player.seek(to: currentTime) { _ in
                player.play()
            }

            // Set up the playerView
            playerView.player = player

            // Overlay the playerView on the drawable
            if let drawable = drawable {
                drawable.addSubview(playerView)
                playerView.translatesAutoresizingMaskIntoConstraints = false
                drawable.addConstraints([
                    playerView.topAnchor.constraint(equalTo: drawable.topAnchor),
                    playerView.bottomAnchor.constraint(equalTo: drawable.bottomAnchor),
                    playerView.leftAnchor.constraint(equalTo: drawable.leftAnchor),
                    playerView.rightAnchor.constraint(equalTo: drawable.rightAnchor),
                ])
            }

            // Create the PIP Controller
            pipController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
            pipController?.delegate = self

            // Wait for the player to start playing before enabling PiP
            var passCount = 0
            pipObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000),
                                                           queue: DispatchQueue.main) { time in
                if passCount == 2 {
                    self.pipController?.startPictureInPicture()
                } else if passCount < 2 {
                    passCount += 1
                }

                if let currentTime = self.nativeMediaPlayer?.currentTime() {
                    self.delegate?.playbackManager(self, didChangeTime: Int32(round(currentTime.seconds * 1000)))
                }
            }
        }
    }

    func stopPictureInPicture() {
        if let nativeMediaPlayer = nativeMediaPlayer {
            if let observer = self.pipObserver {
                nativeMediaPlayer.removeTimeObserver(observer)
            }

            // Stop the PiP player and seek the VLC player to the correct position
            nativeMediaPlayer.pause()
            let currentTime = nativeMediaPlayer.currentTime().seconds
            vlcMediaPlayer.time = VLCTime(int: Int32(currentTime * 1000))
            play()

            // Clear playerView and the nativeMediaPlayer
            playerView.removeFromSuperview()
            playerView.player = nil
            self.nativeMediaPlayer = nil
        }
    }

    // MARK: - Internal state handling
    private func updateSelectedSource() {
        // TODO Evaluate which quality would be useful in stream manager based on available bandwidth / network type
        let quality = preferQuality ?? .hd1080
        if let currentlyPlaying = currentlyPlaying {
            self.selectedSource = try? currentlyPlaying.streamManager.stream(withPreferredQuality: quality,
                                                                             adaptive: true,
                                                                             preferHighFPS: preferHighFPS,
                                                                             preferHDR: preferHDR)
            print(self.selectedSource!)
        }
    }

    private func updatePlayer() {
        // TODO Handle if we are in PiP mode
        // TODO Handle if we were playing previously and resume
        if let selectedSource = selectedSource, let videoUrl = URL(string: selectedSource.video.url) {
            vlcMediaPlayer.media = VLCMedia(url: videoUrl)

            // Add the optional audio source (in case we have an adaptive stream)
            if let audioSource = selectedSource.audio?.url, let audioURL = URL(string: audioSource) {
                vlcMediaPlayer.addPlaybackSlave(audioURL, type: .audio, enforce: true)
            }

            play()
        }
    }
}

extension PlaybackManager: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        delegate?.playbackManager(self, didChangeTime: vlcMediaPlayer.time.intValue)
    }

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        let currentState: VLCMediaPlayerState  = vlcMediaPlayer.state

        // TODO Take a look at isPlaying and willPlay

        // Handle state transitions for states that only make sense when combined
        if previousState == .buffering && currentState == .esAdded {
//            // File was added thus we are currently loading
//            playButton.select(animate: false)
//            playButton.isHidden = true
//            setNeedsDisplay(playButton.frame)
//            loadingIndicator.startAnimating()
//
//            refreshControlHideTimer()
            // TODO Is this necessary here?
//            delegate?.playbackManagerWillLoadMedia(self)
        } else if previousState == .esAdded && currentState == .buffering {
//            // File was loaded and we are buffering -> playing right now
//            loadingIndicator.stopAnimating()
//            playButton.deselect(animate: false)
//            setNeedsDisplay(playButton.frame)
//            playButton.isHidden = false

            vlcMediaPlayer.media.flatMap { delegate?.playbackManagerDidLoadMedia(self, withDuration: $0.length.intValue) }
            delegate?.playbackManagerDidStartPlayback(self)

            // MPNowPlayingInfoCenter
            let duration = vlcMediaPlayer.media.flatMap { Double($0.length.intValue) / 1000 } ?? 0

//            VideoMetadataAPI.shared.thumbnailURL(forVideo: currentlyPlaying!.id).startWithResult { result in
//                if let thumbnailURL = result.value {
//                    UIApplication.shared.beginReceivingRemoteControlEvents()
//
//                    let data = try? Data(contentsOf: thumbnailURL)
//
//                    if let imageData = data {
//                        let image = UIImage(data: imageData)!
//                        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (size) -> UIImage in
//                            return image
//                        })
//
//                        let songInfo: [String : Any] = [
//                            MPMediaItemPropertyTitle: "Random test video",
//                            MPMediaItemPropertyPlaybackDuration: NSNumber(value: duration),
//                            MPMediaItemPropertyArtwork: artwork
//                        ]
//
//                        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
//
//                        let commandCenter = MPRemoteCommandCenter.shared()
//                        commandCenter.playCommand.isEnabled = true
//                        commandCenter.pauseCommand.isEnabled = true
//                        commandCenter.playCommand.addTarget(self, action: #selector(self.play))
//                        commandCenter.pauseCommand.addTarget(self, action: #selector(self.pause))
//                    }
//                }
//            }



//            commandCenter.nextTrackCommand.isEnabled = true
//            commandCenter.nextTrackCommand.addTarget(self, action:#selector(nextTrackCommandSelector))

//            var nowPlayingInfo = [String : Any]()
//            nowPlayingInfo[MPMediaItemPropertyTitle] = NSString(string: "Test video")
//            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: elapsedTime)
//            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: duration)
//            nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.anyVideo
//            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }

        // Handle specific states that can appear by themselves
        switch(currentState) {
        case .ended:
            // TODO: The video feed ends a few seconds short. Figure out why
            delegate?.playbackManagerDidFinishPlayback(self)
            delegate?.playbackManagerDidStopPlayback(self)
        case .stopped:
            delegate?.playbackManagerDidStopPlayback(self)
        case .paused:
            delegate?.playbackManagerDidStopPlayback(self)
        case .playing:
            delegate?.playbackManagerDidStartPlayback(self)
        default:
            break;
        }

        print(currentState.rawValue, vlcMediaPlayer.isPlaying, vlcMediaPlayer.media?.state.rawValue)

        previousState = currentState
    }
}

extension PlaybackManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        stopPictureInPicture()
        delegate?.playbackManagerWillStopPictureInPicture(self)
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        delegate?.playbackManagerWillStartPictureInPicture(self)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // TODO Open the videoDetailView or whatever
    }
}
