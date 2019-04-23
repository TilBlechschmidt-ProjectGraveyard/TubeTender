//
//  VideoAPI.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import struct YoutubeKit.Video
import struct YoutubeKit.VideoListRequest
import ReactiveCocoa
import ReactiveSwift

enum VideoError: Swift.Error {
    case notFound
}

extension Array {
    fileprivate func filterIfPossible(_ predicate: (Element) -> Bool) -> [Element] {
        let filtered = self.filter(predicate)
        return !filtered.isEmpty ? filtered : self
    }
}

public class Video: YoutubeClientObject<YoutubeKit.VideoListRequest, YoutubeKit.Video> {
    public typealias ID = String

    let id: ID

    fileprivate init(id: ID, client: YoutubeClient) {
        self.id = id

        let channelRequest = VideoListRequest(part: [.contentDetails, .statistics, .snippet], filter: .id(id))

        super.init(client: client, request: channelRequest) { response in
            return response.tryMap(VideoError.notFound) { $0.items.count == 1 ? $0.items[0] : nil }
        }
    }

    var thumbnailURL: APISignalProducer<URL> {
        return makeProperty { $0.snippet?.thumbnails.high.url.flatMap(URL.init(string:)) }
    }

    var title: APISignalProducer<String> {
        return makeProperty { $0.snippet?.title }
    }

    var description: APISignalProducer<String> {
        return makeProperty { $0.snippet?.description }
    }

    var published: APISignalProducer<Date> {
        return makeProperty { ($0.snippet?.publishedAt).flatMap(DateFormatter.iso8601Full.date) }
    }

    var durationString: APISignalProducer<String> {
        return makeProperty { $0.contentDetails?.durationPretty }
    }

    var duration: APISignalProducer<TimeInterval> {
        return makeProperty { $0.contentDetails?.durationInterval }
    }

    var viewCount: APISignalProducer<Int> {
        return makeProperty { ($0.statistics?.viewCount).flatMap(Int.init) }
    }

    var channel: APISignalProducer<Channel> {
        return makeProperty { ($0.snippet?.channelID).flatMap(self.client.channel(withID:)) }
    }

    var channelTitle: APISignalProducer<String> {
        return makeProperty { $0.snippet?.channelTitle }
    }

    var isPremium: APISignalProducer<Bool> {
        return makeProperty { $0.statistics?.viewCount == nil }
    }

    var hlsURL: URL {
        return URL(string: "http://localhost:\(Constants.hlsServerPort)/\(self.id).m3u8")!
    }
}

extension YoutubeClient {
    func video(withID id: Video.ID) -> Video {
        return cacheOrCreate(id, &videoCache, Video(id: id, client: self))
    }

    func videos(withIDs ids: [Video.ID]) -> [Video] {
        return ids.map(video(withID:))
    }
}

extension Video: Equatable {
    public static func == (lhs: Video, rhs: Video) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Stream management

//fileprivate let videoInfoPath = "https://www.youtube.com/get_video_info?video_id=%@&asv=3&el=detailpage&ps=default&hl=en_US"
//
//typealias StreamSet = (video: StreamMetadata, audio: StreamMetadata?)
//
//extension Video {
//    func stream(withPreferredQuality preferredQuality: StreamQuality,
//                adaptive: Bool,
//                preferHighFPS: Bool = true,
//                preferHDR: Bool = false) -> SignalProducer<StreamSet, NoError> {
//        return streams.filterMap({ $0.value }).map { streamCollection in
//            let subset = adaptive ? streamCollection.video : streamCollection.mixed
//
//            var bestStream = subset[0]
//
//            for stream in subset[1...] {
//                let hdrMatch = preferHDR && !bestStream.hdr && stream.hdr
//                let fpsMatch = preferHighFPS && !bestStream.highFPS && stream.highFPS
//                let betterSecondaryMatch: Bool
//
//                if fpsMatch {
//                    betterSecondaryMatch = true
//                } else if bestStream.highFPS == stream.highFPS {
//                    betterSecondaryMatch = hdrMatch
//                } else {
//                    betterSecondaryMatch = false
//                }
//
//                if betterSecondaryMatch && bestStream.quality == stream.quality {
//                    bestStream = stream
//                } else if bestStream.quality > preferredQuality && bestStream.quality > stream.quality {
//                    bestStream = stream
//                } else if
//                    bestStream.quality <= preferredQuality
//                        && stream.quality > bestStream.quality
//                        && stream.quality < preferredQuality
//                {
//                    bestStream = stream
//                }
//            }
//
//            let eligibleAudioStreams = streamCollection.audio // .filter { $0.mimeType.contains("mp4") }
//
//            if adaptive, let audioStream = eligibleAudioStreams.first {
//                return (video: bestStream, audio: audioStream)
//            } else {
//                return (video: bestStream, audio: nil)
//            }
//        }
//    }
//}
