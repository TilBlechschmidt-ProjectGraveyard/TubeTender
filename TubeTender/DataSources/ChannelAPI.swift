//
//  ChannelAPI.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 03.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import YoutubeKit
import ReactiveSwift
import ReactiveCocoa

enum ChannelError: Error {
    case requestFailed(error: Error)
    case notFound
}

public class Channel: YoutubeClientObject {
    public typealias ID = String

    public let id: ID

    fileprivate init(id: ID, client: YoutubeClient) {
        self.id = id
        super.init(client: client)
    }

    public var thumbnailURL: SignalProducer<URL, ChannelError> {

    }
}

extension YoutubeClient {
    func channel(withID id: Channel.ID) -> Channel {
        return Channel(id: id, client: self)
    }
}

//class ChannelMetadataAPI {
//    static let shared = ChannelMetadataAPI()
//    private init() {}
//
//    private static let defaultChannelListParts: [Part.ChannelList] = [.contentDetails, .statistics, .snippet]
//
//    func thumbnailURL(forChannel channelID: ChannelID) -> SignalProducer<URL, ChannelMetadataAPIError> {
//        // TODO If we are offline ask the DownloadManager instead.
//        return fetchMetadata(forChannel: channelID, withParts: [.snippet]).attemptMap { channelMetadata in
//            if let urlString = channelMetadata.snippet?.thumbnails.high.url, let url = URL(string: urlString) {
//                return .success(url)
//            } else {
//                return .failure(ChannelMetadataAPIError.notFound)
//            }
//        }
//    }
//
//    func fetchMetadata(forChannel channelID: ChannelID, withParts parts: [Part.ChannelList] = ChannelMetadataAPI.defaultChannelListParts) -> SignalProducer<Channel, ChannelMetadataAPIError> {
//        let channelRequest = ChannelListRequest(part: parts, filter: .id(channelID))
//
//        return ApiSession.shared.reactive.send(channelRequest)
//            .mapError { ChannelMetadataAPIError.requestFailed(error: $0.error) }
//            .attemptMap { response in
//                if response.items.count == 1 {
//                    return .success(response.items[0])
//                } else {
//                    return .failure(ChannelMetadataAPIError.notFound)
//                }
//            }
//    }
//}
//
//
