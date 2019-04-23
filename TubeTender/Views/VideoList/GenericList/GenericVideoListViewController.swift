//
//  GenericVideoListViewController.swift
//  TubeTender
//
//  Created by Noah Peeters on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

class GenericVideoListViewController: UITableViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    private lazy var emptyStateView: UIView = createEmptyStateView()
    private var isLoading: Bool = false

    var isEmpty: Bool = false {
        willSet {
            emptyStateView.isHidden = !newValue
        }
    }

    weak var dataSource: GenericVideoListViewControllerDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SubscriptionFeedViewTableCell.self, forCellReuseIdentifier: SubscriptionFeedViewTableCell.identifier)
        tableView.backgroundColor = Constants.backgroundColor
        tableView.separatorColor = Constants.borderColor
        tableView.refreshControl = UIRefreshControl()

        tableView.refreshControl?.addTarget(self, action: #selector(self.handlePullToRefresh), for: .valueChanged)
        tableView.rowHeight = CGFloat.greatestFiniteMagnitude
        tableView.backgroundView = emptyStateView
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
        tableView.refreshControl?.beginRefreshing()
        isLoading = true
        return true
    }

    func reloadVideos() {
        notUpdating()
    }

    open func loadNextVideos() {
        notUpdating()
    }

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
        let numberOfSections = dataSource.numberOfSections()
        // TODO Find a better way to set the empty state. This doesn't work.
//        emptyStateView.isHidden = numberOfSections == 0
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfRows(in: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SubscriptionFeedViewTableCell(style: .default, reuseIdentifier: nil)
//      let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionFeedViewTableCell.identifier) as! SubscriptionFeedViewTableCell
        cell.hideThumbnail = hideThumbnail(at: indexPath)
        cell.video = dataSource.getVideo(indexPath.section, row: indexPath.row)

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
        let remainingItemsInCurrentSection = dataSource.numberOfRows(in: indexPath.section) - indexPath.row - 1
        let remainingItemsInNextSections = ((indexPath.section + 1)..<dataSource.numberOfSections()).reduce(0) {
            $0 + dataSource.numberOfRows(in: $1)
        }

        let remainingItems = remainingItemsInCurrentSection + remainingItemsInNextSections

        if remainingItems < 10 {
            handleInfiniteScrollLoadRequest()
        }

        var currentIndexPath = indexPath
        var counter = 0

        while counter < 5 {
            currentIndexPath.row += 1

            if dataSource.numberOfRows(in: currentIndexPath.section) >= currentIndexPath.row {
                currentIndexPath = IndexPath(row: 0, section: currentIndexPath.section + 1)
            }

            if dataSource.numberOfSections() >= currentIndexPath.section {
                return
            }

            if dataSource.numberOfRows(in: currentIndexPath.section) >= currentIndexPath.row {
                continue
            }

            dataSource.getVideo(currentIndexPath.section, row: currentIndexPath.row).prefetchData()
            counter += 1
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = Constants.selectedBackgroundColor
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = Constants.labelColor
        }
    }
}

protocol GenericVideoListViewControllerDataSource: class {
    func getVideo(_ section: Int, row: Int) -> Video
    func numberOfSections() -> Int
    func numberOfRows(in section: Int) -> Int
}
