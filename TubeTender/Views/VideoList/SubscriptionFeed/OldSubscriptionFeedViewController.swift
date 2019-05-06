//
//  SubscriptionViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import os.log
import UIKit

class OldSubscriptionFeedViewController: SimpleVideoListViewController {
    private var cutoffDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleLogin), name: .googleSignInSucceeded, object: nil)
    }

    func fetchFeed(cutoffDate: Date?, onCompletion: @escaping ([Video], Date) -> Void) {
        SubscriptionFeedAPI.shared.fetchSubscriptionFeed(publishedBefore: cutoffDate).startWithResult { result in
            switch result {
            case .success(let (videos, cutoffDate)):
                onCompletion(videos, cutoffDate)
            case .failure(let error):
                self.notUpdating()
                os_log("Failed to fetch infinite feed: %@", log: .network, type: .info, error.localizedDescription)
                // TODO Show this to the user.
            }
        }
    }

    @objc private func handleLogin() {
        guard startFetch() else { return }
        reloadVideos()
    }

    override func reloadVideos() {
        fetchFeed(cutoffDate: nil) { videos, cutoffDate in
            self.cutoffDate = cutoffDate
            self.replace(videos: [videos])
        }
    }

    override func loadNextVideos() {
        fetchFeed(cutoffDate: cutoffDate) { videos, cutoffDate in
            self.cutoffDate = cutoffDate
            self.append(videos: videos, toSection: 0)
        }
    }

    override func createEmptyStateView() -> UIView {
        return EmptyStateView(image: #imageLiteral(resourceName: "movie"), text: "No videos found")
    }
}
