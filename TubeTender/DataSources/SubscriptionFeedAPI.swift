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
import Result

class SubscriptionFeedAPI {
    static let shared = SubscriptionFeedAPI()
    private init() {}

    private func fetchSubscribedChannels(pageToken: String? = nil) -> SignalProducer<[Channel.ID], AnyError> {
        let subscriptionRequest = SubscriptionsListRequest(part: [.snippet],
                                                           filter: .mine(true),
                                                           forChannelID: nil,
                                                           maxResults: 50,
                                                           onBehalfOfContentOwner: nil,
                                                           onBehalfOfContentOwnerChannel: nil,
                                                           order: nil,
                                                           pageToken: pageToken)

        return ApiSession.shared.reactive.send(subscriptionRequest).flatMap(.concat) { response -> SignalProducer<[Channel.ID], AnyError> in
            var channelIDs = response.items.compactMap { $0.snippet?.resourceID.channelID }

            if let nextPageToken = response.nextPageToken {
                return self.fetchSubscribedChannels(pageToken: nextPageToken).map { nextPageChannelIDs in
                    channelIDs.append(contentsOf: nextPageChannelIDs)
                    return channelIDs
                }
            } else {
                return SignalProducer(value: channelIDs)
            }
        }
    }

    func fetchSubscriptionFeed(publishedBefore: Date? = nil) -> SignalProducer<(videos: [Video], endDate: Date), AnyError> {
        return fetchSubscribedChannels().flatMap(.latest) {
            self.fetchSubscriptionFeed(forChannels: $0, publishedBefore: publishedBefore)
        }
    }

    private func fetchSubscriptionFeed(forChannels channelIDs: [Channel.ID], publishedBefore: Date?) -> SignalProducer<(videos: [Video], endDate: Date), AnyError> {
        return SignalProducer(channelIDs).flatMap(.concurrent(limit: 25)) {
            self.fetchSubscriptionFeed(forChannel: $0, publishedBefore: publishedBefore)
        }.collect().map { videoSets in
            // Calculate the date of the most recent of the least recent videos
            let cutoffDate: Date = videoSets.compactMap { videoSet in
                videoSet.min(by: { $0.publishedAt < $1.publishedAt })?.publishedAt
            }.max { $0 < $1 }!

            // Remove videos after the cutoff date from each set and flatten the sets into one
            let videos = videoSets.flatMap { videoSet in
                videoSet.filter { $0.publishedAt >= cutoffDate }
            }

            // Sort the videos by publish date and strip the date
            let sortedVideos = videos.sorted { $0.publishedAt > $1.publishedAt }.map { $0.video }

            return (videos: sortedVideos, endDate: cutoffDate)
        }
    }

    private func fetchSubscriptionFeed(forChannel channelID: Channel.ID, publishedBefore: Date?) -> SignalProducer<[(video: Video, publishedAt: Date)], AnyError> {
        let activityFeedRequest = ActivityListRequest(part: [.contentDetails, .snippet],
                                                      filter: .channelID(channelID),
                                                      maxResults: 50,
                                                      publishedBefore: publishedBefore)

        return ApiSession.shared.reactive.send(activityFeedRequest).map { response in
            return response.items.compactMap {
                guard let videoID = $0.contentDetails?.upload?.videoID,
                    let snippet = $0.snippet,
                    let publishDate = DateFormatter.iso8601Full.date(from: snippet.publishedAt) else {
                        return nil
                }

                return (video: YoutubeClient.shared.video(withID: videoID), publishedAt: publishDate)
            }
        }
    }
}
