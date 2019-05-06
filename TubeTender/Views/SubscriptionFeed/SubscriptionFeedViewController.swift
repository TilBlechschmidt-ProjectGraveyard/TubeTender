//
//  SubscriptionFeedViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 05.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class SubscriptionFeedViewController: UIViewController {
    private let subscriptionListViewController = SubscriptionFeedGridViewController(videoPlayer: VideoPlayer.shared)
    private let channelListView: ChannelListView
    private let borderView = UIView()

    private let compact: Bool

    init(compact: Bool = UIDevice.current.userInterfaceIdiom == .phone) {
        channelListView = ChannelListView(compact: compact)
        self.compact = compact

        super.init(nibName: nil, bundle: nil)

        self.title = "Subscriptions"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.addSubview(channelListView)
        channelListView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()

            if compact {
                make.right.equalToSuperview()
                // Intrinsic content height
            } else {
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

        view.addSubview(subscriptionListViewController.view)
        subscriptionListViewController.view.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()

            if compact {
                make.top.equalTo(borderView.snp.bottom)
                make.left.equalToSuperview()
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.left.equalTo(borderView.snp.right)
            }
        }

        view.bringSubviewToFront(channelListView)
        view.bringSubviewToFront(borderView)

        NotificationCenter.default.addObserver(self, selector: #selector(self.handleLogin), name: .googleSignInSucceeded, object: nil)
    }

    @objc func handleLogin() {
        subscriptionListViewController.setNeedsNewData()
        SubscriptionFeedAPI.shared.subscribedChannels().startWithResult { result in
            if let channels = result.value {
                self.channelListView.channels = channels
            }
        }
    }
}
