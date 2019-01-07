//
//  ChannelAPI.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 03.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import struct YoutubeKit.Channel
import struct YoutubeKit.ChannelListRequest
import Result
import ReactiveSwift
import ReactiveCocoa

enum ChannelError: Swift.Error {
    case notFound
}

public class Channel: YoutubeClientObject<YoutubeKit.ChannelListRequest, YoutubeKit.Channel> {
    public typealias ID = String

    public let id: ID

    fileprivate init(id: ID, client: YoutubeClient) {
        let channelRequest = ChannelListRequest(part: [.contentDetails, .statistics, .snippet], filter: .id(id))

        self.id = id
        super.init(client: client, request: channelRequest) { response in
            return response.tryMap(ChannelError.notFound) { $0.items.count == 1 ? $0.items[0] : nil }
        }
    }

    var thumbnailURL: APISignalProducer<URL> {
        return makeProperty { $0.snippet?.thumbnails.high.url.flatMap { URL(string: $0) } }
    }

    var title: APISignalProducer<String> {
        return makeProperty { $0.snippet?.title }
    }

    var subscriptionCount: APISignalProducer<Int> {
        return makeProperty { ($0.statistics?.subscriberCount).flatMap { Int($0) } }
    }
}

extension YoutubeClient {
    func channel(withID id: Channel.ID) -> Channel {
        return cacheOrCreate(id, &channelCache, Channel(id: id, client: self))
    }
}
