//
//  VideoMetadataViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

class VideoMetadataViewController: UIViewController {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = "."
        formatter.numberStyle = .decimal
        return formatter
    }()

    let videoMetadataView = VideoMetadataView()

    var video: Video! {
        didSet {
            downloadButtonViewController.video = video
            fetchVideoDetails()
        }
    }

    private let downloadButtonViewController = VideoDownloadButtonViewController()

    public weak var delegate: VideoMetadataViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)

        videoMetadataView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        videoMetadataView.downloadButtonView = downloadButtonViewController.view
        videoMetadataView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoMetadataView)
        view.addConstraints([
            videoMetadataView.topAnchor.constraint(equalTo: view.topAnchor),
            videoMetadataView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoMetadataView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoMetadataView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    func fetchVideoDetails() {
        videoMetadataView.videoTitle.reactive.text <~ video.title.map { $0.value ?? "Loading..." }
        videoMetadataView.videoDescriptionView.reactive.text <~ video.description.map { $0.value ?? "Loading..." }
        videoMetadataView.viewCount.reactive.text <~ video.viewCount.map { result -> String? in
            if let viewCount = result.value, let viewsString = VideoMetadataViewController.numberFormatter.string(from: NSNumber(value: viewCount)) {
                return "\(viewsString) views"
            } else {
                return nil
            }
        }

        let channel = video.channel

        videoMetadataView.channelThumbnail.reactive.setImage(options: [.transition(.fade(0.5))]) <~ channel.get(\.thumbnailURL).map { $0.value }
        videoMetadataView.channelTitle.reactive.text <~ channel.get(\.title).map { $0.value ?? "Failed!!!!" }
        videoMetadataView.channelSubscriberCount.reactive.text <~ channel.get(\.subscriptionCount).map {
            "\($0.value?.unitFormatted ?? "??") subscribers"
        }
    }
}

extension VideoMetadataViewController: VideoMetadataViewDelegate {
    func handle(url: URL, rect: CGRect, view: UIView) -> Bool {
        return delegate?.handle(url: url, rect: rect, view: view) ?? false
    }
}

public protocol VideoMetadataViewControllerDelegate: class {
    func handle(url: URL, rect: CGRect, view: UIView) -> Bool
}
