//
//  HomeFeedGridViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 02.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

class HomeFeedGridViewController: GenericVideoGridViewController {
    let homeFeedAPI = HomeFeedAPI()
    let youtubeClient = YoutubeClient.shared

    override func resetData() {
        homeFeedAPI?.clearContinuationData()
    }

    override func fetchNextData() -> SignalProducer<[GenericVideoGridViewSection], Error> {
        guard let api = homeFeedAPI else {
            return SignalProducer(error: HomeFeedAPIError.noContinuationAvailable)
        }

        let dataSections = api.canContinue ? api.fetchHomeFeedContinuation() : api.fetchHomeFeed()

        return dataSections
            .flatten()
            .map {
                let videos = self.youtubeClient.videos(withIDs: $0.items.map { $0.videoID })
                return GenericVideoGridViewSection(
                    title: $0.title,
                    subtitle: $0.subtitle,
                    icon: $0.thumbnailURL,
                    items: videos
                )
            }
            .collect()
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section >= sections.count - 2 {
            setNeedsNewData()
        }
    }
}
