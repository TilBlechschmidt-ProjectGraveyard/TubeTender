//
//  SubscriptionFeed.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation
import YoutubeKit

class SubscriptionFeed {
    var subscribedChannels: [String]?

    func fetchSubscribedChannels(_ callbackClosure: @escaping (_ channelIDs: [String]) -> Void) {
        let subscriptionRequest = SubscriptionsListRequest(part: [.snippet],
                                                           filter: .mine(true),
                                                           forChannelID: nil,
                                                           maxResults: 50,
                                                           onBehalfOfContentOwner: nil,
                                                           onBehalfOfContentOwnerChannel: nil,
                                                           order: nil,
                                                           pageToken: nil)

        ApiSession.shared.send(subscriptionRequest) { result in
            switch result {
            case .success(let response):
                let channelIDs = response.items.compactMap { $0.snippet?.resourceID.channelID }

                if response.pageInfo.resultsPerPage < response.pageInfo.totalResults {
                    // TODO Fetch consecutive pages as well
                    print("WARNING: There are more subscribed channels than we fetched. Fix this!")
                }

                self.subscribedChannels = channelIDs

                callbackClosure(channelIDs)
            case .failed(let error):
                // TODO Show error message
                print(error)
            }
        }
    }

    func fetchActivityFeed(_ completion: @escaping ([Entry]) -> ()) {
        if let subscribedChannels = self.subscribedChannels {
            fetchActivityFeed(forChannels: subscribedChannels, with: completion)
        } else {
            fetchSubscribedChannels { channels in
                self.fetchActivityFeed(forChannels: channels, with: completion)
            }
        }
    }

    func fetchActivityFeed(forChannels channelIDs: [String], with completion: @escaping ([Entry]) -> ()) {
        // TODO Rework this with reactive swift
        // TODO Run this sequentially this is REALLY heavy
        var remaining = channelIDs.count
        var feedEntries: [Entry] = []

        channelIDs.forEach { channelID in
            self.fetchActivityFeed(forChannel: channelID) {
                // TODO Implement a cutoff date.
                // If the least recent entry of this channel is the most recent of all least recent ones
                // then we should truncate all other videos (since every channel only has 15 videos fetched
                // so when one published 15 videos a day less recent videos would be missing in the list)
                feedEntries.append(contentsOf: $0)
                remaining -= 1
                if remaining == 0 {
                    // Filter out entries that are listed but not yet published (future publish date)
                    feedEntries = feedEntries.filter { $0.published <= Date() }
                    // Sort by publish date
                    feedEntries.sort { $0.published > $1.published }
                    
                    completion(feedEntries)
                }
            }
        }
    }

    func fetchActivityFeed(forChannel channelID: String, with completion: @escaping ([Entry]) -> ()) {
        guard let url = URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(channelID)") else {
            completion([])
            return
        }

        let parser = YoutubeVideoFeedParser()
        completion(parser.startParsing(rssURL: url))
    }
}
