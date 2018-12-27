//
//  SubscriptionFeedTableCell.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import Kingfisher
import YoutubeKit

class SubscriptionFeedViewTableCell: UITableViewCell {
    let uiPadding: CGFloat = 15.0
    let channelIconSize: CGFloat = 45.0

    let thumbnailView = UIImageView()
    let metadataView = UIView()
    let videoMetaTitleView = UIView()
    let videoTitleView = UILabel()
    let videoSubtitleView = UILabel()
    let channelIconView = UIImageView()

    let durationView = UIView()
    let durationLabelView = UILabel()

    var _entry: Entry!
    var entry: Entry {
        get {
            return _entry
        }
        set {
            // Video duration
            // TODO Add a duration label
//            durationLabelView.text = newValue

            // Video title
            videoTitleView.text = newValue.title

            // Video subtitle
            videoSubtitleView.text = ""
            if let channelName = newValue.authorName {
                videoSubtitleView.text?.append("\(channelName) ∙ ")
            }
            if let viewCount = newValue.viewCount {
                videoSubtitleView.text?.append("\(viewCount.withThousandSeparators) views ∙ ")
            }
            videoSubtitleView.text?.append(newValue.published.since())

            // Thumbnail
            if let thumbnailString = newValue.thumbnail, let thumbnailURL = URL(string: thumbnailString.url) {
                thumbnailView.kf.indicatorType = .activity
                let processor = RoundCornerImageProcessor(cornerRadius: 20)
                thumbnailView.kf.setImage(with: thumbnailURL, options: [.processor(processor), .transition(.fade(0.5))])
            }

            // Channel icon
            // TODO Cache the URL (not only the image)
            if let channelID = newValue.channelID {
                let channelMetadataRequest = ChannelListRequest(part: [.snippet], filter: .id(channelID))

                ApiSession.shared.send(channelMetadataRequest) { result in
                    switch result {
                    case .success(let response):
                        if let iconURLString = response.items.first?.snippet?.thumbnails.default.url,
                            let iconURL = URL(string: iconURLString)
                        {
                            self.channelIconView.kf.indicatorType = .activity
                            self.channelIconView.kf.setImage(with: iconURL, options: [.transition(.fade(0.5))])
                        }
                    case .failed(let error):
                        // TODO Show error message
                        print(error)
                    }
                }
            }

            _entry = newValue
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
