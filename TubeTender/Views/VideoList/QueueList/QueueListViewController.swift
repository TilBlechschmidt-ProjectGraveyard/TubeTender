//
//  QueueListViewController.swift
//  TubeTender
//
//  Created by Noah Peeters on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import ReactiveSwift

class QueueListViewController: GenericVideoListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let data = SignalProducer.zip(
            PlaybackQueue.default.history,
            PlaybackQueue.default.currentItem,
            PlaybackQueue.default.queue)

        data.startWithValues { [weak self] data in
            self?.replace(videos: [
                Array(data.0),
                data.1.flatMap { [$0] } ?? [],
                Array(data.2)
            ])
        }
    }

    override func hideThumbnail(at indexPath: IndexPath) -> Bool {
        return indexPath.section != 1
    }

    override func headerTitle(forSection section: Int) -> String? {
        return ["History", "Playing", "Up Next"][section]
    }

    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
        return false
    }
}
