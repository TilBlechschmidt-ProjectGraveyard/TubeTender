//
//  VideoAPI.swift
//  Pivo
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import struct YoutubeKit.Video
//import struct YoutubeKit.VideoList
import struct YoutubeKit.VideoListRequest
import Result
import ReactiveSwift
import ReactiveCocoa

enum VideoError: Swift.Error {
    case notFound
}

//public class VideoList: YoutubeClientObject<YoutubeKit.VideoListRequest, YoutubeKit.VideoList> {
//    fileprivate init(ids: [Video.ID], client: YoutubeClient) {
//        let channelRequest = VideoListRequest(part: [.contentDetails, .statistics, .snippet], filter: .id(ids.joined(separator: ",")))
//
//        super.init(client: client, request: channelRequest, mapResponse: { $0 })
//    }
//}

public class Video: YoutubeClientObject<YoutubeKit.VideoListRequest, YoutubeKit.Video> {
    public typealias ID = String

    fileprivate init(id: ID, client: YoutubeClient) {
        let channelRequest = VideoListRequest(part: [.contentDetails, .statistics, .snippet], filter: .id(id))

        super.init(client: client, request: channelRequest) { response in
            return response.tryMap(VideoError.notFound) { $0.items.count == 1 ? $0.items[0] : nil }
        }
    }

    var id: APISignalProducer<ID> {
        return makeProperty { $0.id }
    }

    var thumbnailURL: APISignalProducer<URL> {
        return makeProperty { $0.snippet?.thumbnails.high.url.flatMap { URL(string: $0) } }
    }

    var title: APISignalProducer<String> {
        return makeProperty { $0.snippet?.title }
    }

    var description: APISignalProducer<String> {
        return makeProperty { $0.snippet?.description }
    }

    var published: APISignalProducer<Date> {
        return makeProperty { ($0.snippet?.publishedAt).flatMap { DateFormatter.iso8601Full.date(from: $0) } }
    }

    // TODO Make this a TimeInterval
    var duration: APISignalProducer<String> {
        return makeProperty { $0.contentDetails?.durationPretty }
    }

    var viewCount: APISignalProducer<Int> {
        return makeProperty { ($0.statistics?.viewCount).flatMap { Int($0) } }
    }

    var channel: APISignalProducer<Channel> {
        return makeProperty { ($0.snippet?.channelID).flatMap { self.client.channel(withID: $0) } }
    }

    var channelTitle: APISignalProducer<String> {
        return makeProperty { $0.snippet?.channelTitle }
    }

    var isPremium: APISignalProducer<Bool> {
        return makeProperty { $0.statistics?.viewCount == nil }
    }
}

extension YoutubeClient {
    func video(withID id: Video.ID) -> Video {
        return cacheOrCreate(id, &videoCache, Video(id: id, client: self))
    }

    func videos(withIDs ids: [Video.ID]) -> [Video] {
        return ids.map { video(withID: $0) }
    }
}
