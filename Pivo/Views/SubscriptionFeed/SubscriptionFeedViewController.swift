//
//  SubscriptionViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit

class SubscriptionFeedViewController: UIViewController {
    let viewTransition = DraggableViewTransition()
    var tableView = UITableView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    var items: [Entry] = []

    let feed = SubscriptionFeed()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0.141, green: 0.141, blue: 0.141, alpha: 1)
        tableView.backgroundColor = nil
        tableView.separatorColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        tableView.register(SubscriptionFeedViewTableCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = view.frame.width * 0.5625 + 75
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
                self.feed.fetchActivityFeed { feed in
                    print("Feed fetched! \(feed.count) entries")
                    DispatchQueue.main.async {
                        self.items = feed
                        self.tableView.reloadData()
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
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? SubscriptionFeedViewTableCell
        if cell == nil {
            cell = SubscriptionFeedViewTableCell(style: .default, reuseIdentifier: "Cell")
        }

        cell?.entry = items[indexPath.row]

        return cell!
    }
}

extension SubscriptionFeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let videoID = items[indexPath.row].videoID {
            let videoDetailView = viewTransition.createVideoDetailViewController(withID: videoID)
            present(videoDetailView, animated: true, completion: nil)
        }
        return nil
    }
}
