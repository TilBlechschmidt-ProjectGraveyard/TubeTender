//
//  SubscriptionFeedAPI.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation
import YoutubeKit
import ReactiveSwift


enum SubscriptionFeedAPIError: Error {
    case requestFailed(error: Error)
}

class SubscriptionFeedAPI {
    static let shared = SubscriptionFeedAPI()
    private init() {}

    func fetchSubscribedChannels(pageToken: String? = nil) -> SignalProducer<[Channel.ID], SubscriptionFeedAPIError> {
        return SignalProducer { observer, _ in
            let subscriptionRequest = SubscriptionsListRequest(part: [.snippet],
                                                               filter: .mine(true),
                                                               forChannelID: nil,
                                                               maxResults: 50,
                                                               onBehalfOfContentOwner: nil,
                                                               onBehalfOfContentOwnerChannel: nil,
                                                               order: nil,
                                                               pageToken: pageToken)

            ApiSession.shared.send(subscriptionRequest) { result in
                switch result {
                case .success(let response):
                    var channelIDs = response.items.compactMap { $0.snippet?.resourceID.channelID }

                    if let nextPageToken = response.nextPageToken {
                        self.fetchSubscribedChannels(pageToken: nextPageToken).startWithResult { result in
                            if let error = result.error {
                                observer.send(error: error)
                                observer.sendCompleted()
                            } else if let nextPageChannelIDs = result.value {
                                channelIDs.append(contentsOf: nextPageChannelIDs)
                                observer.send(value: channelIDs)
                                observer.sendCompleted()
                            }
                        }
                    } else {
                        observer.send(value: channelIDs)
                        observer.sendCompleted()
                    }
                case .failed(let error):
                    observer.send(error: .requestFailed(error: error))
                    observer.sendCompleted()
                }
            }
        }
    }

    func fetchSubscriptionFeed() -> SignalProducer<(videoIDs: [VideoID], endDate: Date), SubscriptionFeedAPIError> {
        return fetchSubscribedChannels().flatMap(.latest) { self.fetchSubscriptionFeed(forChannels: $0) }
    }

    func fetchSubscriptionFeed(forChannels channelIDs: [Channel.ID]) -> SignalProducer<(videoIDs: [VideoID], endDate: Date), SubscriptionFeedAPIError> {
        return SignalProducer(channelIDs).flatMap(.concurrent(limit: 25)) {
            self.fetchSubscriptionFeed(forChannel: $0)
        }.collect().map { videoSets in
            let cutoffDate: Date = videoSets.compactMap { videoSet in
                videoSet.min(by: { $0.publishedAt < $1.publishedAt })?.publishedAt
            }.max { $0 < $1 }!

            let videoIDs = videoSets.flatMap { videoSet in
                videoSet.filter { $0.publishedAt > cutoffDate }.map { $0.0 }
            }

            return (videoIDs: videoIDs, endDate: cutoffDate)
        }
    }

    func fetchSubscriptionFeed(forChannel channelID: Channel.ID) -> SignalProducer<[(videoID: VideoID, publishedAt: Date)], SubscriptionFeedAPIError> {
        return SignalProducer { observer, _ in
            let activityFeedRequest = ActivityListRequest(part: [.contentDetails, .snippet],
                                                          filter: .channelID(channelID),
                                                          maxResults: 20,
                                                          pageToken: nil,
                                                          publishedAfter: nil,
                                                          publishedBefore: nil,
                                                          regionCode: nil)

            ApiSession.shared.send(activityFeedRequest) { result in
                switch result {
                case .success(let response):
                    let videoIDs: [(VideoID, Date)] = response.items.compactMap {
                        guard let videoID = $0.contentDetails?.upload?.videoID,
                            let snippet = $0.snippet,
                            let publishDate = DateFormatter.iso8601Full.date(from: snippet.publishedAt) else {
                                return nil
                        }

                        return (videoID: videoID, publishedAt: publishDate)
                    }
                    observer.send(value: videoIDs)
                    observer.sendCompleted()
                case .failed(let error):
                    observer.send(error: .requestFailed(error: error))
                    observer.sendCompleted()
                }
            }
        }
    }
}
