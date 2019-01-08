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

class SubscriptionFeedViewController: UIViewController {
    private var tableView = UITableView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    private var items: [Video] = []

    override func viewDidLayoutSubviews() {
        // TODO This produces bogus view widths
        tableView.rowHeight = view.frame.width * 0.5625 + 75
    }

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

        tableView.am.addPullToRefresh { [unowned self] in
            DispatchQueue.global(qos: .userInitiated).async {
                let subscriptionFeed = SubscriptionFeedAPI.shared.fetchSubscriptionFeed()

                let metaFeed = subscriptionFeed.flatMap(FlattenStrategy.merge) { (videoIDs, endDate) -> SignalProducer<([Video], Date), NoError> in
                    let endDateProducer = SignalProducer<Date, NoError>(value: endDate)
                    let videoProducer = SignalProducer(YoutubeClient.shared.videos(withIDs: videoIDs))
                        .map { SignalProducer(value: $0).zip(with: $0.published).zip(with: $0.viewCount) }
                        .flatten(.concat)
                        .filterMap { $0.1.value != nil ? $0.0 : nil }
                        .collect()
                        .map { (videoList: [(Video, APIResult<Date>)]) -> [Video] in
                            videoList.sorted { $0.1.value ?? Date() > $1.1.value ?? Date() }.map { data -> Video in data.0 }
                        }
                    return videoProducer.zip(with: endDateProducer)
                }

                metaFeed.startWithResult { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let (videos, endDate)):
                            print("Feed fetched! \(videos.count) entries.")
                            self.items = videos
                            self.tableView.reloadData()
                        case .failure(let error):
                            print("Failed to fetch feed!", error)
                            // TODO Show this to the user.
                        }
                        self.tableView.am.pullToRefreshView?.stopRefreshing()
                    }
                }
            }
        }

//        tableView.am.addInfiniteScrolling { [unowned self] in
//            self.fetchMoreData(completion: { (fetchedItems) in
//                self.items.append(contentsOf: fetchedItems)
//                self.tableView.reloadData()
//                self.tableView.am.infiniteScrollingView?.stopRefreshing()
//                if fetchedItems.count == 0 {
//                    //No more data is available
//                    self.tableView.am.infiniteScrollingView?.hideInfiniteScrollingView()
//                }
//            })
//        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refresh),
                                               name: NSNotification.Name("AppDelegate.authentication.loggedIn"),
                                               object: nil)
    }

    @objc func refresh() {
        tableView.am.pullToRefreshView?.trigger()
    }

//    func fetchDataFromStart(completion handler:@escaping (_ fetchedItems: [Int])->Void) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            let fetchedItems = Array(0..<self.kPageLength)
//            handler(fetchedItems)
//        }
//    }
//
//    func fetchMoreData(completion handler:@escaping (_ fetchedItems: [Int])->Void) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            if self.items.count >= self.kMaxItemCount {
//                handler([])
//                return
//            }
//
//            let fetchedItems = Array(self.items.count..<(self.items.count + self.kPageLength))
//            handler(fetchedItems)
//        }
//    }
}

extension SubscriptionFeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SubscriptionFeedViewTableCell(video: items[indexPath.row])

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
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let video = items[indexPath.row]

        // TODO Snowball into playback manager and make it not use IDs but Video instead.
        video.id.startWithValues { result in
            if let id = result.value {
                PlaybackManager.shared.playNow(videoID: id).startWithResult { _ in
                    DispatchQueue.main.async {
                        // TODO replace segue with self.showDetailViewController(vc, sender: self)
                        self.performSegue(withIdentifier: "showDetail", sender: self)
                    }
                }
            }
        }

        return nil
    }
}
