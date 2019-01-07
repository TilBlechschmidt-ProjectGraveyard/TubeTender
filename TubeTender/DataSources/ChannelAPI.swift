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
}

public class Channel: YoutubeClientObject<YoutubeKit.ChannelListRequest, YoutubeKit.Channel> {
    public typealias ID = String

    public let id: ID

    fileprivate init(id: ID, client: YoutubeClient) {
        let channelRequest = ChannelListRequest(part: [.contentDetails, .statistics, .snippet], filter: .id(id))

        self.id = id
        super.init(client: client,
                   request: channelRequest,
                   mapResponse: { response in
                        return response.attemptMap { response in
                            if response.items.count == 1 {
                                return response.items[0]
                            } else {
                                throw AnyError(ChannelError.notFound)
                            }
                        }
                    })
    }

    var thumbnailURL: SignalProducer<URL?, NoError> {
        return response.map {
            $0.snippet?.thumbnails.high.url.flatMap { URL(string: $0) }
        }
    }
}

extension YoutubeClient {
    func channel(withID id: Channel.ID) -> Channel {
        return Channel(id: id, client: self)
    }
}
