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

enum ChannelError: Error {
    case notFound
    case invalidAPIResponse
}

public class Channel: YoutubeClientObject<YoutubeKit.ChannelListRequest, YoutubeKit.Channel> {
    public typealias ID = String

    public let id: ID

    fileprivate init(id: ID, client: YoutubeClient) {
        let channelRequest = ChannelListRequest(part: [.contentDetails, .statistics, .snippet], filter: .id(id))

        self.id = id
        super.init(client: client, request: channelRequest) { response in
            return response.map {
                $0.tryMap {
                    if $0.items.count == 1 {
                        return $0.items[0]
                    } else {
                        throw AnyError(ChannelError.notFound)
                    }
                }
            }
        }
    }

    var thumbnailURL: APISignalProducer<URL> {
        return response.tryMap(ChannelError.invalidAPIResponse) {
            $0.snippet?.thumbnails.high.url.flatMap { URL(string: $0) }
        }
    }

    var title: APISignalProducer<String> {
        return response.tryMap(ChannelError.invalidAPIResponse) {
            $0.snippet?.title
        }
    }

    var subscriptionCount: APISignalProducer<Int> {
        return response.tryMap(ChannelError.invalidAPIResponse) {
            return ($0.statistics?.subscriberCount).flatMap { Int($0) }
        }
    }
}

extension YoutubeClient {
    func channel(withID id: Channel.ID) -> Channel {
        return Channel(id: id, client: self)
    }
}
