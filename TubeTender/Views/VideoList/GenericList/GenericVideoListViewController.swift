//
//  GenericVideoListViewController.swift
//  TubeTender
//
//  Created by Noah Peeters on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import ReactiveSwift

class GenericVideoListViewController: UITableViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    public var items = MutableProperty<[Video]>([])

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SubscriptionFeedViewTableCell.self, forCellReuseIdentifier: SubscriptionFeedViewTableCell.identifier)
        tableView.backgroundColor = Constants.backgroundColor
        tableView.separatorColor = Constants.borderColor
        tableView.refreshControl = UIRefreshControl()

        tableView.refreshControl?.addTarget(self, action: #selector(self.reloadVideos), for: .valueChanged)
        tableView.rowHeight = CGFloat.greatestFiniteMagnitude

        let initialLoadingIndicator = UIActivityIndicatorView(style: .white)
        initialLoadingIndicator.startAnimating()
        initialLoadingIndicator.reactive.isHidden <~ items.map { $0.count > 0 }
        tableView.backgroundView = initialLoadingIndicator

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(gestureRecognizer:)))
        tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let pressLocation = gestureRecognizer.location(in: tableView)

        guard let indexPath = tableView.indexPathForRow(at: pressLocation) else { return }

        IncomingVideoReceiver.default.handle(
            video: self.items.value[indexPath.row],
            source: .rect(rect: tableView.rectForRow(at: indexPath), view: tableView, permittedArrowDirections: .left))
    }

    func append(videos: [Video]) {
        let previousLength = self.items.value.count

        self.items.value.append(contentsOf: videos)

        let indexPaths = (previousLength..<self.items.value.count).map { IndexPath(row: $0, section: 0) }
        self.tableView.insertRows(at: indexPaths, with: .fade)
        self.tableView.refreshControl?.endRefreshing()
    }

    func replace(videos: [Video]) {
        self.items.value = videos
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }

    @objc func reloadVideos() {}

    open func loadNextVideos() {}
}

extension GenericVideoListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionFeedViewTableCell.identifier) as? SubscriptionFeedViewTableCell
        if cell == nil {
            cell = SubscriptionFeedViewTableCell(style: .default, reuseIdentifier: SubscriptionFeedViewTableCell.identifier)
        }
        cell?.video = items.value[indexPath.row]

        return cell!
    }
}

extension GenericVideoListViewController {
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width * 0.5625 + 75
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width * 0.5625 + 75
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row > items.value.count - 10 {
            loadNextVideos()
        }

        for index in (indexPath.row+1)..<min(indexPath.row + 5, items.value.count) {
            items.value[index].prefetchData()
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let video = items.value[indexPath.row]

        self.showDetailViewController(VideoViewController(), sender: self)
        SwitchablePlayer.shared.playbackItem.value = video

        return nil
    }
}
