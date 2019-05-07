//
//  SubscriptionFeedViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 05.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class SubscriptionFeedViewController: UIViewController {
    private let feedAPI: SubscriptionFeedAPI

    private let subscriptionListViewController: SubscriptionFeedGridViewController
    private let channelListView: ChannelListView
    private let channelActivityIndicator = UIActivityIndicatorView()
    private let borderView = UIView()

    private let compact: Bool

    init(videoPlayer: VideoPlayer, incomingVideoReceiver: IncomingVideoReceiver, subscriptionFeedAPI: SubscriptionFeedAPI, compact: Bool = UIDevice.current.userInterfaceIdiom == .phone) {
        self.channelListView = ChannelListView(compact: compact)
        self.compact = compact
        self.feedAPI = subscriptionFeedAPI
        self.subscriptionListViewController = SubscriptionFeedGridViewController(videoPlayer: videoPlayer, incomingVideoReceiver: incomingVideoReceiver, subscriptionFeedAPI: subscriptionFeedAPI)

        super.init(nibName: nil, bundle: nil)

        self.title = "Subscriptions"
        self.tabBarItem = UITabBarItem(title: self.title, image: #imageLiteral(resourceName: "movie"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        let channelListViewHeight = Constants.channelIconSize + 2 * Constants.uiPadding
        view.addSubview(channelListView)
        channelListView.snp.makeConstraints { make in
            make.left.equalToSuperview()

            if compact {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.right.equalToSuperview()
                make.height.equalTo(channelListViewHeight)
            } else {
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(300)
            }
        }

        borderView.backgroundColor = Constants.borderColor
        view.addSubview(borderView)
        borderView.snp.makeConstraints { make in
            if compact {
                make.top.equalTo(channelListView.snp.bottom)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(1)
            } else {
                make.left.equalTo(channelListView.snp.right)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(1)
            }
        }

        addChild(subscriptionListViewController)
        view.addSubview(subscriptionListViewController.view)
        subscriptionListViewController.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()

            if compact {
                make.left.equalToSuperview()
            } else {
                make.left.equalTo(borderView.snp.right)
            }
        }
        subscriptionListViewController.didMove(toParent: self)

        if compact {
            subscriptionListViewController.collectionView.contentInset = UIEdgeInsets(top: channelListViewHeight + 1, left: 0, bottom: 0, right: 0)
        }

        view.bringSubviewToFront(channelListView)
        view.bringSubviewToFront(borderView)

        channelActivityIndicator.tintColor = .white
        channelActivityIndicator.hidesWhenStopped = true
        view.addSubview(channelActivityIndicator)
        channelActivityIndicator.snp.makeConstraints { make in
            make.center.equalTo(channelListView)
        }

        channelActivityIndicator.startAnimating()
        subscriptionListViewController.setNeedsNewData(clearingPreviousData: true)
        feedAPI.subscribedChannels().startWithResult { result in
            if let channels = result.value {
                self.channelListView.channels = channels
                self.channelActivityIndicator.stopAnimating()
            }
        }
    }
}
