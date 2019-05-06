//
//  CommandCenter.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 10.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import MediaPlayer
import ReactiveCocoa
import ReactiveSwift

enum CommandCenterAction {
    case play
    case pause
    case next
    case previous
    case seek(toTime: TimeInterval)
}

protocol CommandCenterDelegate: class {
    func commandCenter(_ commandCenter: CommandCenter, didReceiveCommand: CommandCenterAction) -> MPRemoteCommandHandlerStatus
}

class CommandCenter: NSObject {
    weak var delegate: CommandCenterDelegate?

    let isEnabled = MutableProperty<Bool>(false)
    let hasNext = MutableProperty<Bool>(false)
    let hasPrevious = MutableProperty<Bool>(false)

    let title = MutableProperty<String?>(nil)
    let artist = MutableProperty<String?>(nil)

    let elapsedTime = MutableProperty<TimeInterval?>(nil)
    let duration = MutableProperty<TimeInterval?>(nil)

    let thumbnail = MutableProperty<UIImage?>(nil)

    override init() {
        super.init()
        isEnabled.signal.observeValues { enabled in
            if enabled {
                UIApplication.shared.beginReceivingRemoteControlEvents()
            } else {
                UIApplication.shared.endReceivingRemoteControlEvents()
            }
        }

        observe(property: isEnabled)
        observe(property: title)
        observe(property: artist)
        observe(property: elapsedTime)
        observe(property: duration)
        observe(property: thumbnail)

        let commandCenter = MPRemoteCommandCenter.shared()

        createHandler(forCommand: commandCenter.playCommand) { _ in
            return self.delegate?.commandCenter(self, didReceiveCommand: .play)
        }

        createHandler(forCommand: commandCenter.pauseCommand) { _ in
            return self.delegate?.commandCenter(self, didReceiveCommand: .pause)
        }

        createHandler(forCommand: commandCenter.changePlaybackPositionCommand) { (event: MPChangePlaybackPositionCommandEvent) in
            return self.delegate?.commandCenter(self, didReceiveCommand: .seek(toTime: event.positionTime))
        }

        createHandler(forCommand: commandCenter.nextTrackCommand) { _ in
            return self.delegate?.commandCenter(self, didReceiveCommand: .next)
        }

        createHandler(forCommand: commandCenter.previousTrackCommand) { _ in
            return self.delegate?.commandCenter(self, didReceiveCommand: .previous)
        }

        hasNext.signal.observeValues { commandCenter.nextTrackCommand.isEnabled = $0 }
        hasPrevious.signal.observeValues { commandCenter.previousTrackCommand.isEnabled = $0 }
    }

    @discardableResult
    func load(video: Video) -> Disposable {
        let thumbnail = video.channel.get(\.thumbnailURL).filterMap { thumbnailURL in
            return thumbnailURL.value.map { (url: URL) -> UIImage? in
                let data = try? Data(contentsOf: url)
                return data.flatMap(UIImage.init(data:))
            }
        }
        return SignalProducer.zip(video.title, video.channelTitle, thumbnail).startWithValues { result in
            self.title.value = result.0.value
            self.artist.value = result.1.value
            self.thumbnail.value = result.2
        }
    }

    private func createHandler<CommandEvent: MPRemoteCommandEvent>(forCommand command: MPRemoteCommand,
                                                                   _ closure: @escaping (CommandEvent) -> MPRemoteCommandHandlerStatus?) {
        command.isEnabled = true
        command.addTarget { (event: MPRemoteCommandEvent) in
            let castedEvent = event as? CommandEvent
            return castedEvent.flatMap(closure) ?? .commandFailed
        }
    }

    private func observe<T>(property: MutableProperty<T>) {
        property.signal.observeValues { [unowned self] _ in
            self.updateSongInfo()
        }
    }

    private func updateSongInfo() {
        var songInfo: [String: Any] = [
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        if let title = title.value { songInfo[MPMediaItemPropertyTitle] = title }
        if let artist = artist.value { songInfo[MPMediaItemPropertyArtist] = artist }

        if let elapsedTime = elapsedTime.value { songInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime }
        if let duration = duration.value { songInfo[MPMediaItemPropertyPlaybackDuration] = duration }

        if let thumbnail = thumbnail.value {
            songInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: thumbnail.size) { _ in thumbnail }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    }
}
