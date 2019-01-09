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

    private lazy var emptyStateView: UIView = createEmptyStateView()

    public var videos: [[Video]] = [] {
        didSet {
            emptyStateView.isHidden = videos.count > 0
        }
    }

    private var isLoading: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SubscriptionFeedViewTableCell.self, forCellReuseIdentifier: SubscriptionFeedViewTableCell.identifier)
        tableView.backgroundColor = Constants.backgroundColor
        tableView.separatorColor = Constants.borderColor
        tableView.refreshControl = UIRefreshControl()

        tableView.refreshControl?.addTarget(self, action: #selector(self.handlePullToRefresh), for: .valueChanged)
        tableView.rowHeight = CGFloat.greatestFiniteMagnitude
        tableView.backgroundView = emptyStateView

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(gestureRecognizer:)))
        tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let pressLocation = gestureRecognizer.location(in: tableView)

        guard let indexPath = tableView.indexPathForRow(at: pressLocation) else { return }

        IncomingVideoReceiver.default.handle(
            video: self.videos[0][indexPath.row],
            source: .rect(rect: tableView.rectForRow(at: indexPath), view: tableView, permittedArrowDirections: .left))
    }

    func append(videos: [Video], toSection section: Int = 0) {
        let previousLength = self.videos[section].count

        self.videos[section].append(contentsOf: videos)

        let indexPaths = (previousLength..<self.videos[section].count).map { IndexPath(row: $0, section: section) }
        self.tableView.insertRows(at: indexPaths, with: .fade)
        self.tableView.refreshControl?.endRefreshing()
        isLoading = false
    }

    func replace(videos: [[Video]]) {
        self.videos = videos
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
        isLoading = false
    }

    func notUpdating() {
        self.tableView.refreshControl?.endRefreshing()
        isLoading = false
    }

    @objc private func handlePullToRefresh() {
        guard startFetch() else { return }
        reloadVideos()
    }

    private func handleInfiniteScrollLoadRequest() {
        guard startFetch() else { return }
        loadNextVideos()
    }

    func startFetch() -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        return true
    }

    func reloadVideos() {}

    open func loadNextVideos() {}

    open func createEmptyStateView() -> UIView {
        return UIView()
    }

    open func headerTitle(forSection section: Int) -> String? {
        return nil
    }

    open func hideThumbnail(at indexPath: IndexPath) -> Bool {
        return false
    }
}

extension GenericVideoListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return videos.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionFeedViewTableCell.identifier) as! SubscriptionFeedViewTableCell
        cell.video = videos[indexPath.section][indexPath.row]
        cell.hideThumbnail = hideThumbnail(at: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerTitle(forSection: section)
    }
}

extension GenericVideoListViewController {
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (hideThumbnail(at: indexPath) ? 0 : tableView.frame.width * 0.5625) + Constants.channelIconSize + 2 * Constants.uiPadding
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let remainingItemsInCurrentSection = videos[indexPath.section].count - indexPath.row - 1
        let remainingItemsInNextSections = videos[(indexPath.section + 1)...].reduce(0) { return $0 + $1.count }
        let remainingItems = remainingItemsInCurrentSection + remainingItemsInNextSections

        if remainingItems < 10 {
            handleInfiniteScrollLoadRequest()
        }

        var currentIndexPath = indexPath

        for _ in 1...5 {
            if videos[currentIndexPath.section].count > currentIndexPath.row + 1 {
                currentIndexPath.row += 1
            } else if videos.count > currentIndexPath.section + 1 {
                currentIndexPath = IndexPath(row: 0, section: currentIndexPath.section + 1)
            } else {
                return
            }

            videos[currentIndexPath.section][currentIndexPath.row].prefetchData()
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let video = videos[indexPath.section][indexPath.row]

        self.showDetailViewController(VideoViewController(), sender: self)
        SwitchablePlayer.shared.playbackItem.value = video

        return nil
    }
}
