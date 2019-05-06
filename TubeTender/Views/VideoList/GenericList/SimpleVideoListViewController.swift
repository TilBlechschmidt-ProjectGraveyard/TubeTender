//
//  SimpleVideoListViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 23.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class SimpleVideoListViewController: GenericVideoListViewController {
    public let videoPlayer: VideoPlayer

    public var videos: [[Video]] = [] {
        didSet {
            super.isEmpty = videos.isEmpty
        }
    }

    init(videoPlayer: VideoPlayer) {
        self.videoPlayer = videoPlayer
        super.init(nibName: nil, bundle: nil)

        self.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let video = self.dataSource.getVideo(indexPath.section, row: indexPath.row)
        videoPlayer.playNow(video)

        return nil
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let playLaterAction = UIContextualAction(style: .normal, title: "Play next") { [unowned self] _, _, success in
            self.videoPlayer.playNext(self.getVideo(indexPath.section, row: indexPath.row))
            success(true)
        }
        playLaterAction.backgroundColor = Constants.primaryActionColor

        return UISwipeActionsConfiguration(actions: [playLaterAction])
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let playLaterAction = UIContextualAction(style: .normal, title: "Play later") { [unowned self] _, _, success in
            self.videoPlayer.playLater(self.getVideo(indexPath.section, row: indexPath.row))
            success(true)
        }
        playLaterAction.backgroundColor = Constants.secondaryActionColor

        return UISwipeActionsConfiguration(actions: [playLaterAction])
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
