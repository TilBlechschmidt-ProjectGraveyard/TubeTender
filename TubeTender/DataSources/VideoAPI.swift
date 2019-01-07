//
//  VideoAPI.swift
//  Pivo
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import struct YoutubeKit.Video
import struct YoutubeKit.VideoListRequest
import Result
import ReactiveSwift
import ReactiveCocoa

enum VideoError: Swift.Error {
    case notFound
}

public class Video: YoutubeClientObject<YoutubeKit.VideoListRequest, YoutubeKit.Video> {
    public typealias ID = String

    public let id: ID

    fileprivate init(id: ID, client: YoutubeClient) {
        let channelRequest = VideoListRequest(part: [.contentDetails, .statistics, .snippet], filter: .id(id))

        self.id = id
        super.init(client: client, request: channelRequest) { response in
            return response.tryMap(VideoError.notFound) { $0.items.count == 1 ? $0.items[0] : nil }
        }
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

    var viewCount: APISignalProducer<Int> {
        return makeProperty { ($0.statistics?.viewCount).flatMap { Int($0) } }
    }

    var channel: APISignalProducer<Channel> {
        return makeProperty { ($0.snippet?.channelID).flatMap { self.client.channel(withID: $0) } }
    }
}

extension YoutubeClient {
    func video(withID id: Video.ID) -> Video {
        return Video(id: id, client: self)
    }
}
