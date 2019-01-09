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

class SubscriptionFeedViewController: UIViewController {
    private var tableView = UITableView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    private var items = MutableProperty<[Video]>([])
    private var cutoffDate: Date?
    private var isFetching = false

    private let placeholder = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO Only hide when not on a small screen.
        self.navigationController?.navigationBar.isHidden = true

        view.backgroundColor = UIColor(red: 0.141, green: 0.141, blue: 0.141, alpha: 1)
        tableView.backgroundColor = nil
        tableView.separatorColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        tableView.register(SubscriptionFeedViewTableCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addConstraints([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        ])

        tableView.refreshControl = UIRefreshControl()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refresh),
                                               name: NSNotification.Name("AppDelegate.authentication.loggedIn"),
                                               object: nil)

        tableView.refreshControl?.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        tableView.rowHeight = CGFloat.greatestFiniteMagnitude

        placeholder.text = "Loading ..."
        placeholder.textColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        placeholder.textAlignment = .center
        placeholder.reactive.isHidden <~ items.map { $0.count > 0 }
        tableView.backgroundView = placeholder

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(gestureRecognizer:)))
        tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    func fetchFeed(cutoffDate: Date?, onCompletion: @escaping ([Video], Date) -> Void) {
        guard !isFetching else {
            tableView.refreshControl?.endRefreshing()
            return
        }
        isFetching = true
        SubscriptionFeedAPI.shared.fetchSubscriptionFeed(publishedBefore: cutoffDate).startWithResult { result in
            switch result {
            case .success(let (videos, cutoffDate)):
                onCompletion(videos, cutoffDate)
            case .failure(let error):
                print("Failed to fetch infinite feed!", error)
                // TODO Show this to the user.
            }
            self.isFetching = false
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    @objc func refresh() {
        tableView.refreshControl?.beginRefreshing()
        fetchFeed(cutoffDate: nil) { videos, cutoffDate in
            self.items.value = videos
            self.cutoffDate = cutoffDate
            self.tableView.reloadData()
        }
    }

    func fetchNextSet() {
        fetchFeed(cutoffDate: cutoffDate) { videos, cutoffDate in
            let previousLength = self.items.value.count

            self.items.value.append(contentsOf: videos)
            self.cutoffDate = cutoffDate

            let indexPaths = (previousLength..<self.items.value.count).map { IndexPath(row: $0, section: 0) }
            self.tableView.insertRows(at: indexPaths, with: .fade)
        }
    }

    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let pressLocation = gestureRecognizer.location(in: tableView)

        guard let indexPath = tableView.indexPathForRow(at: pressLocation) else { return }

        IncomingVideoReceiver.default.handle(
            video: self.items.value[indexPath.row],
            source: .rect(rect: tableView.rectForRow(at: indexPath), view: tableView, permittedArrowDirections: .left))
    }
}

extension SubscriptionFeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SubscriptionFeedViewTableCell(video: items.value[indexPath.row])

        // TODO Implement cell reusability
//        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? SubscriptionFeedViewTableCell
//        if cell == nil {
//            cell = SubscriptionFeedViewTableCell(style: .default, reuseIdentifier: "Cell")
//        }
//        cell?.video = items[indexPath.row]

        return cell
    }
}

extension SubscriptionFeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width * 0.5625 + 75
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width * 0.5625 + 75
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row > items.value.count - 10 {
            fetchNextSet()
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let video = items.value[indexPath.row]

        // TODO Snowball into playback manager and make it not use IDs but Video instead.
        PlaybackManager.shared.playNow(videoID: video.id).startWithResult { _ in
            DispatchQueue.main.async {
                // TODO replace segue with self.showDetailViewController(vc, sender: self)
                self.performSegue(withIdentifier: "showDetail", sender: self)
            }
        }

        return nil
    }
}
