//
//  SubscriptionViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import YoutubeKit
import ReactiveSwift
import Result
import ReactiveCocoa

class SubscriptionFeedViewController: GenericVideoListViewController {
    private var cutoffDate: Date?
    private var isFetching = false

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reloadVideos),
                                               name: NSNotification.Name("AppDelegate.authentication.loggedIn"),
                                               object: nil)
    }

    func fetchFeed(cutoffDate: Date?, onCompletion: @escaping ([Video], Date) -> Void) {
        guard !isFetching else {
            return
        }
        isFetching = true
        SubscriptionFeedAPI.shared.fetchSubscriptionFeed(publishedBefore: cutoffDate).startWithResult { result in
            switch result {
            case .success(let (videos, cutoffDate)):
                onCompletion(videos, cutoffDate)
            case .failure(let error):
                self.notUpdating()
                print("Failed to fetch infinite feed!", error)
                // TODO Show this to the user.
            }
            self.isFetching = false
        }
    }

    override func reloadVideos() {
        tableView.refreshControl?.beginRefreshing()
        fetchFeed(cutoffDate: nil) { videos, cutoffDate in
            self.cutoffDate = cutoffDate
            self.replace(videos: videos)
        }
    }

    override func loadNextVideos() {
        fetchFeed(cutoffDate: cutoffDate) { videos, cutoffDate in
            self.cutoffDate = cutoffDate
            self.append(videos: videos)
        }
    }

    override var emptyStateView: EmptyStateView {
        return EmptyStateView(image: #imageLiteral(resourceName: "movie"), text: "No videos found")
    }
}
