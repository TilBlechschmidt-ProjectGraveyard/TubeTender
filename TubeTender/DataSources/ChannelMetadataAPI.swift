//
//  ChannelMetadataAPI.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 03.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import YoutubeKit
import ReactiveSwift

enum ChannelMetadataAPIError: Error {
    case requestFailed(error: Error)
    case notFound
}

class ChannelMetadataAPI {
    static let shared = ChannelMetadataAPI()
    private init() {}

    private static let defaultChannelListParts: [Part.ChannelList] = [.contentDetails, .statistics, .snippet]

    func thumbnailURL(forChannel channelID: ChannelID) -> SignalProducer<URL, ChannelMetadataAPIError> {
        // TODO If we are offline ask the DownloadManager instead.
        return fetchMetadata(forChannel: channelID, withParts: [.snippet]).attemptMap { channelMetadata in
            if let urlString = channelMetadata.snippet?.thumbnails.high.url, let url = URL(string: urlString) {
                return .success(url)
            } else {
                return .failure(ChannelMetadataAPIError.notFound)
            }
        }
    }

    func fetchMetadata(forChannel channelID: ChannelID, withParts parts: [Part.ChannelList] = ChannelMetadataAPI.defaultChannelListParts) -> SignalProducer<Channel, ChannelMetadataAPIError> {
        return SignalProducer { observer, _ in
            let channelRequest = ChannelListRequest(part: parts, filter: .id(channelID))

            ApiSession.shared.send(channelRequest) { result in
                switch result {
                case .success(let response):
                    if response.items.count == 1 {
                        observer.send(value: response.items[0])
                    } else {
                        observer.send(error: .notFound)
                    }
                case .failed(let error):
                    observer.send(error: .requestFailed(error: error))
                }
                observer.sendCompleted()
            }
        }
    }
}
