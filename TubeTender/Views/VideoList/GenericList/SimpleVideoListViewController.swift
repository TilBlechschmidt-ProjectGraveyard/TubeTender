//
//  SimpleVideoListViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 23.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

class SimpleVideoListViewController: GenericVideoListViewController {
    public var videos: [[Video]] = []

    override func viewDidLoad() {
        super.dataSource = self
        super.viewDidLoad()
    }

    func append(videos: [Video], toSection section: Int) {
        let previousLength = self.videos[section].count

        self.videos[section].append(contentsOf: videos)

        let indexPaths = (previousLength..<self.videos[section].count).map { IndexPath(row: $0, section: section) }
        self.tableView.insertRows(at: indexPaths, with: .fade)
        notUpdating()
    }

    func replace(videos: [[Video]]) {
        self.videos = videos
        self.tableView.reloadData()
        notUpdating()
    }
}

extension SimpleVideoListViewController: GenericVideoListViewControllerDataSource {
    func numberOfSections() -> Int {
        return videos.count
    }

    func numberOfRows(in section: Int) -> Int {
        return videos[section].count
    }

    func getVideo(_ section: Int, row: Int) -> Video {
        return videos[section][row]
    }
}
