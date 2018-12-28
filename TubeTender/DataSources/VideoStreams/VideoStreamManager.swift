//
//  VideoStreamManager.swift
//  Pivo
//
//  Created by Til Blechschmidt on 04.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

fileprivate func groupByQuality(_ streams: [StreamMetadata]) -> [StreamQuality : [StreamMetadata]] {
    return streams.reduce(into: [:]) { result, stream in
        if result[stream.quality] != nil {
            result[stream.quality]?.append(stream)
        } else {
            result[stream.quality] = [stream]
        }
    }
}

extension Array {
    fileprivate func filterIfPossible(_ predicate: (Element) -> Bool) -> [Element] {
        let filtered = self.filter(predicate)
        return filtered.count > 0 ? filtered : self
    }
}

typealias StreamSet = (video: StreamMetadata, audio: StreamMetadata?)

enum VideoStreamManagerError: Error {
    case noAvailableStream
}

class VideoStreamManager {
    let mixedStreams: [StreamQuality : [StreamMetadata]]
    let videoStreams: [StreamQuality : [StreamMetadata]]
    let audioStreams: [StreamAudioQuality : [StreamMetadata]]
    let streams: StreamCollection

    init(withStreams streams: StreamCollection) {
        self.streams = streams
        mixedStreams = groupByQuality(streams.mixed)
        videoStreams = groupByQuality(streams.video)
        audioStreams = streams.video.reduce(into: [:]) { result, stream in
            if let audioQuality = stream.audioQuality {
                if result[audioQuality] != nil {
                    result[audioQuality]?.append(stream)
                } else {
                    result[audioQuality] = [stream]
                }
            }
        }
    }

    func stream(withPreferredQuality quality: StreamQuality,
                adaptive: Bool,
                preferHighFPS: Bool = true,
                preferHDR: Bool = false) throws -> StreamSet {
        var subset = adaptive ? streams.video : streams.mixed

        // TODO Fall back to closest possible lower quality instead of highest
        subset = subset.filterIfPossible { $0.quality == quality }
        subset.sort { $0.quality > $1.quality }

        // TODO Remove this temporary test filter
        subset = subset.filter { $0.mimeType.contains("mp4") }

        // TODO This might work the other way around to at least resolve one of the two constraints
        if preferHighFPS {
            subset = subset.filterIfPossible { $0.highFPS }
        }

        if preferHDR {
            subset = subset.filterIfPossible { $0.hdr }
        }

        guard let stream = subset.first else {
            throw VideoStreamManagerError.noAvailableStream
        }

        let eligibleAudioStreams = streams.audio.filter { $0.mimeType.contains("mp4") }

        if adaptive, let audioStream = eligibleAudioStreams.first {
            return (video: stream, audio: audioStream)
        } else {
            return (video: stream, audio: nil)
        }
    }
}
