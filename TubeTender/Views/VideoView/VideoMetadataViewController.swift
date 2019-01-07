//
//  VideoMetadataViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import YoutubeKit
import ReactiveSwift

class VideoMetadataViewController: UIViewController {
    let videoMetadataView = VideoMetadataView()

    var videoID: String! {
        didSet {
            if oldValue != videoID {
                downloadButtonViewController.videoID = videoID
                fetchVideoDetails()
            }
        }
    }

    private let downloadButtonViewController = VideoDownloadButtonViewController()

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = "."
        formatter.numberStyle = .decimal
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        videoMetadataView.downloadButtonView = downloadButtonViewController.view
        videoMetadataView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoMetadataView)
        view.addConstraints([
            videoMetadataView.topAnchor.constraint(equalTo: view.topAnchor),
            videoMetadataView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoMetadataView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoMetadataView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
    }


    func fetchVideoDetails() {
        VideoMetadataAPI.shared.fetchMetadata(forVideo: videoID!, withParts: [.snippet, .statistics])
            .startWithResult() { result in
                switch result {
                case .success(let videoMetadata):
                    let snippet = videoMetadata.snippet!
                    let stats = videoMetadata.statistics!

                    DispatchQueue.main.async {
                        self.videoMetadataView.videoTitle.text = snippet.title

                        if let views = Int(stats.viewCount ?? "0"),
                            let viewsString = VideoMetadataViewController.numberFormatter.string(from: NSNumber(value: views)) {
                            self.videoMetadataView.viewCount.text = "\(viewsString) views"
                        }

                        self.videoMetadataView.videoDescriptionView.text = snippet.description

                        self.fetchChannelDetails(forID: snippet.channelID)
                    }
                case .failure(let error):
                    print(error)
                }
            }
    }

    func fetchChannelDetails(forID channelID: Channel.ID) {
        let channel = YoutubeClient.shared.channel(withID: channelID)

        channel.thumbnailURL.startWithResult { result in
            if let thumbnailURL = thumbnailURL.value {
                self.videoMetadataView.channelThumbnail.kf.indicatorType = .activity
                self.videoMetadataView.channelThumbnail.kf.setImage(with: thumbnailURL, options: [.transition(.fade(0.5))])
            }
        }

        ChannelMetadataAPI.shared.fetchMetadata(forChannel: channelID, withParts: [.snippet, .statistics]).startWithResult() { result in
            switch result {
            case .success(let channelMetadata):
                let snippet = channelMetadata.snippet!
                let stats = channelMetadata.statistics!

                DispatchQueue.main.async {
                    self.videoMetadataView.channelTitle.text = snippet.title

                    if let subscriberCount = Int(stats.subscriberCount) {
                        self.videoMetadataView.channelSubscriberCount.text = "\(subscriberCount.unitFormatted) subscribers"
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
