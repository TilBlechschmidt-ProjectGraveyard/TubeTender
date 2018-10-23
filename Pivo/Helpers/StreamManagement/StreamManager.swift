//
//  StreamManager.swift
//  Pivo
//
//  Created by Til Blechschmidt on 10.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

struct VideoStreamSource {
    let type: VideoStream
    let url: String
}

struct AudioStreamSource {
    let type: AudioStream
    let url: String
}

class StreamManager {
    let videoSources: [VideoStreamSource]
    let audioSources: [AudioStreamSource]

    init(streams: [(type: StreamType, url: String)]) {
        let (audio, video): ([AudioStreamSource], [VideoStreamSource]) = streams.reduce(into: (audio: [], video: [])) { result, stream in
            switch stream.type {
            case .audio(let audioStream):
                result.0.append(AudioStreamSource(type: audioStream, url: stream.url))
            case .video(let videoStream):
                result.1.append(VideoStreamSource(type: videoStream, url: stream.url))
            }
        }

        videoSources = video
        audioSources = audio
    }

    func source() -> VideoStreamSource {
        return videoSources.filter { $0.type.format == .mp4 }.max { $0.type.quality?.rawValue ?? 0 < $1.type.quality?.rawValue ?? 0 }!
    }

    func bestAvailableSource() -> (video: VideoStreamSource?, audio: AudioStreamSource?) {
        let sourcesByQuality: [VideoStreamQuality: [VideoStreamSource]] = videoSources.reduce(into: [:]) { result, source in
            if let quality = source.type.quality {
                if var qualityGroup = result[quality] {
                    qualityGroup.append(source)
                } else {
                    result[quality] = [source]
                }
            }
        }

        let highestQualitySources = sourcesByQuality.max { $0.key.rawValue < $1.key.rawValue }

        guard let highestQualitySource = highestQualitySources?.value[0] else {
            return (video: nil, audio: nil)
        }

        var audioSource: AudioStreamSource? = nil
        if highestQualitySource.type.format == .mpegDash || highestQualitySource.type.format == .webmDash {
            audioSource = audioSources.max { $0.type.bitrate < $1.type.bitrate }
        }

        return (video: highestQualitySource, audio: audioSource)
    }
}
