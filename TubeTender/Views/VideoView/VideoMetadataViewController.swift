//
//  VideoMetadataViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import YoutubeKit

class VideoMetadataViewController: UIViewController {
    let videoMetadataView = VideoMetadataView()

    var videoID: String! {
        didSet {
            fetchVideoDetails()
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = "."
        formatter.numberStyle = .decimal
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

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
        let request = VideoListRequest(part: [.snippet, .statistics], filter: .id(videoID))

        ApiSession.shared.send(request) { result in
            switch result {
            case .success(let response):
                if let snippet = response.items.first?.snippet, let stats = response.items.first?.statistics {
                    DispatchQueue.main.async {
                        self.videoMetadataView.videoTitle.text = snippet.title

                        if let views = Int(stats.viewCount),
                            let viewsString = VideoMetadataViewController.numberFormatter.string(from: NSNumber(value: views)) {
                            self.videoMetadataView.viewCount.text = "\(viewsString) views"
                        }

                        self.videoMetadataView.videoDescriptionView.text = snippet.description
                    }

                    self.fetchChannelDetails(forID: snippet.channelID)
                }
            case .failed(let error):
                // TODO Show error message
                print(error)
            }
        }
    }

    func fetchChannelDetails(forID channelID: String) {
        let request = ChannelListRequest(part: [.snippet, .statistics, .topicDetails], filter: .id(channelID))

        ApiSession.shared.send(request) { result in
            switch result {
            case .success(let response):
                if let snippet = response.items.first?.snippet, let stats = response.items.first?.statistics {
                    DispatchQueue.main.async {
                        self.videoMetadataView.channelTitle.text = snippet.title

                        if let subscriberCount = Int(stats.subscriberCount) {
                            self.videoMetadataView.channelSubscriberCount.text = "\(subscriberCount.unitFormatted) subscribers"
                        }

                        if let thumbnailURL = snippet.thumbnails.default.url {
                            self.videoMetadataView.channelThumbnail.downloaded(from: thumbnailURL)
                        }
                    }
                }
            case .failed(let error):
                // TODO Show error message
                print(error)
            }
        }
    }
}
