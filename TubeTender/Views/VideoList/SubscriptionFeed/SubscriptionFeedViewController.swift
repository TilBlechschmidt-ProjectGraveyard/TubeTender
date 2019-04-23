//
//  SubscriptionViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit

class SubscriptionFeedViewController: SimpleVideoListViewController {
    private var cutoffDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleLogin),
                                               name: NSNotification.Name("AppDelegate.authentication.loggedIn"),
                                               object: nil)
    }

    func fetchFeed(cutoffDate: Date?, onCompletion: @escaping ([Video], Date) -> Void) {
        SubscriptionFeedAPI.shared.fetchSubscriptionFeed(publishedBefore: cutoffDate).startWithResult { result in
            switch result {
            case .success(let (videos, cutoffDate)):
                onCompletion(videos, cutoffDate)
            case .failure(let error):
                self.notUpdating()
                print("Failed to fetch infinite feed!", error)
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
            self.append(videos: videos)
        }
    }

    override func createEmptyStateView() -> UIView {
        return EmptyStateView(image: #imageLiteral(resourceName: "movie"), text: "No videos found")
    }
}
