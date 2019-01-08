//
//  SubscriptionFeedTableCell.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import Kingfisher
import ReactiveSwift
import Result
import SnapKit

class SubscriptionFeedViewTableCell: UITableViewCell {
    let uiPadding: CGFloat = 15.0
    let channelIconSize: CGFloat = 45.0

    let thumbnailView = UIImageView()
    let lockView = UIImageView(image: #imageLiteral(resourceName: "lock"))
    let metadataView = UIView()
    let videoMetaTitleView = UIView()
    let videoTitleView = UILabel()
    let videoSubtitleView = UILabel()
    let channelIconView = UIImageView()

    let durationView = UIView()
    let durationLabelView = UILabel()

    let video: Video

    init(video: Video) {
        self.video = video
        super.init(style: .default, reuseIdentifier: nil)

        layoutCell()
        populateData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutCell() {
        backgroundColor = nil
        selectedBackgroundView = nil

        // TODO Set the selected color

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailView)
        addConstraints([
            thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: uiPadding),
            thumbnailView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: uiPadding),
            thumbnailView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -uiPadding),
            thumbnailView.heightAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.5625)
        ])

        durationView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationView)
        addConstraints([
            durationView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -uiPadding),
            durationView.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor),
        ])

        durationLabelView.font = durationLabelView.font.withSize(10)
        durationLabelView.textColor = UIColor.white
        durationLabelView.translatesAutoresizingMaskIntoConstraints = false
        durationView.addSubview(durationLabelView)
        addConstraints([
            durationLabelView.leftAnchor.constraint(equalTo: durationView.leftAnchor, constant: uiPadding / 3),
            durationLabelView.rightAnchor.constraint(equalTo: durationView.rightAnchor, constant: -(uiPadding / 3)),
            durationLabelView.topAnchor.constraint(equalTo: durationView.topAnchor, constant: uiPadding / 3),
            durationLabelView.bottomAnchor.constraint(equalTo: durationView.bottomAnchor, constant: -(uiPadding / 3)),
        ])

        durationView.blur(style: .dark, cornerRadius: 10, corners: [.layerMinXMinYCorner])

        thumbnailView.addSubview(lockView)
        lockView.snp.makeConstraints { make in
            make.center.equalTo(thumbnailView)
            make.height.equalTo(lockView.snp.width)
            make.height.equalTo(thumbnailView).dividedBy(5)
        }
        lockView.contentMode = .scaleAspectFit
        lockView.tintColor = Constants.backgroundColor
        let thumbnailBlur = thumbnailView.blur(style: .light)
        thumbnailBlur.isHidden = true
        thumbnailBlur.reactive.isHidden <~ video.isPremium.map { !($0.value ?? false) }

        metadataView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metadataView)
        addConstraints([
            metadataView.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor),
            metadataView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            metadataView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        let bottomClip = metadataView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomClip.priority = .defaultHigh
        bottomClip.isActive = true

        channelIconView.backgroundColor = UIColor.lightGray
        channelIconView.layer.cornerRadius = channelIconSize / 2
        channelIconView.layer.masksToBounds = false
        channelIconView.clipsToBounds = true
        channelIconView.translatesAutoresizingMaskIntoConstraints = false
        metadataView.addSubview(channelIconView)
        metadataView.addConstraints([
            channelIconView.topAnchor.constraint(equalTo: metadataView.topAnchor, constant: uiPadding),
            channelIconView.bottomAnchor.constraint(equalTo: metadataView.bottomAnchor, constant: -uiPadding),
            channelIconView.leftAnchor.constraint(equalTo: metadataView.leftAnchor, constant: uiPadding),
            channelIconView.heightAnchor.constraint(equalToConstant: channelIconSize),
            channelIconView.widthAnchor.constraint(equalToConstant: channelIconSize)
        ])

        videoMetaTitleView.translatesAutoresizingMaskIntoConstraints = false
        metadataView.addSubview(videoMetaTitleView)
        metadataView.addConstraints([
            videoMetaTitleView.centerYAnchor.constraint(equalTo: channelIconView.centerYAnchor),
            videoMetaTitleView.leftAnchor.constraint(equalTo: channelIconView.rightAnchor, constant: uiPadding),
            videoMetaTitleView.rightAnchor.constraint(equalTo: metadataView.rightAnchor, constant: -uiPadding)
        ])

        videoTitleView.font = videoTitleView.font.withSize(13)
        videoTitleView.textColor = UIColor.white
        videoTitleView.lineBreakMode = .byTruncatingTail
        videoTitleView.numberOfLines = 2
        videoTitleView.translatesAutoresizingMaskIntoConstraints = false
        videoMetaTitleView.addSubview(videoTitleView)
        videoMetaTitleView.addConstraints([
            videoTitleView.leftAnchor.constraint(equalTo: videoMetaTitleView.leftAnchor),
            videoTitleView.rightAnchor.constraint(equalTo: videoMetaTitleView.rightAnchor),
            videoTitleView.topAnchor.constraint(equalTo: videoMetaTitleView.topAnchor)
        ])

        videoSubtitleView.font = videoSubtitleView.font.withSize(11)
        videoSubtitleView.textColor = UIColor.lightGray
        videoSubtitleView.lineBreakMode = .byTruncatingTail
        videoSubtitleView.translatesAutoresizingMaskIntoConstraints = false
        videoMetaTitleView.addSubview(videoSubtitleView)
        videoMetaTitleView.addConstraints([
            videoSubtitleView.leftAnchor.constraint(equalTo: videoMetaTitleView.leftAnchor),
            videoSubtitleView.rightAnchor.constraint(equalTo: videoMetaTitleView.rightAnchor),
            videoSubtitleView.topAnchor.constraint(equalTo: videoTitleView.bottomAnchor, constant: uiPadding / 4),
            videoSubtitleView.bottomAnchor.constraint(equalTo: videoMetaTitleView.bottomAnchor)
        ])
    }

    func populateData() {
        // Video duration
        durationLabelView.reactive.text <~ video.duration.map { $0.value ?? "--:--" }

        // Video title
        videoTitleView.reactive.text <~ video.title.map { $0.value ?? "Loading ..." }

        // Video subtitle
        let subtitleData = SignalProducer.zip(
            video.channelTitle.map { $0.value },
            video.viewCount.map { $0.value },
            video.published.map { $0.value },
            video.isPremium.map { $0.value }
        )

        let subtitle: SignalProducer<String, NoError> = subtitleData.map { data in
            let (channelTitle, viewCount, published, isPremium) = data

            let displayData = [
                channelTitle ?? "Loading ...",
                (isPremium ?? false) ? "Premium Content" : viewCount.map { "\($0.withThousandSeparators) views" },
                published?.since()
            ]

            return displayData.compactMap({ $0 }).joined(separator: " ∙ ")
        }
        videoSubtitleView.reactive.text <~ subtitle

        lockView.isHidden = true
        lockView.reactive.isHidden <~ video.isPremium.map { !($0.value ?? false) }

        // Thumbnail
        let processor = RoundCornerImageProcessor(cornerRadius: 20)
        thumbnailView.reactive.setImage(options: [.processor(processor), .transition(.fade(0.5))]) <~ video.thumbnailURL.map { $0.value }

        // Channel icon
        let channel = video.channel
        channelIconView.reactive.setImage(options: [.transition(.fade(0.5))]) <~ channel.get(\.thumbnailURL).map { $0.value }
    }

}
