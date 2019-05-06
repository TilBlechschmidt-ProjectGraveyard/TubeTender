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
    init(videoPlayer: VideoPlayer) {
        super.init(videoPlayer: videoPlayer, fetchInitialData: false, sectionBased: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fetchNextData() -> SignalProducer<[GenericVideoGridViewSection], Error> {
        return SubscriptionFeedAPI.shared.fetchSubscriptionFeed()
            .map { GenericVideoGridViewSection(title: "", subtitle: nil, icon: nil, items: $0.videos) }
            .collect()
    }
}
