//
//  SubscriptionFeedGridViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 05.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

class SubscriptionFeedGridViewController: GenericVideoGridViewController {
    private let feedAPI: SubscriptionFeedAPI

    init(videoPlayer: VideoPlayer, incomingVideoReceiver: IncomingVideoReceiver, subscriptionFeedAPI: SubscriptionFeedAPI) {
        feedAPI = subscriptionFeedAPI
        super.init(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver, fetchInitialData: false, sectionBased: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fetchNextData() -> SignalProducer<[GenericVideoGridViewSection], Error> {
        return feedAPI.fetchSubscriptionFeed()
            .map { GenericVideoGridViewSection(title: "", subtitle: nil, icon: nil, items: $0.videos) }
            .collect()
    }
}
