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
    let thumbnailView = UIImageView()
    let durationView = DurationView()
    let lockView = UIImageView(image: #imageLiteral(resourceName: "lock"))

    let metadataView = UIView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let channelIconView = UIImageView()

    let video: Video

    init(video: Video) {
        self.video = video
        super.init(style: .default, reuseIdentifier: nil)

        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = nil
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = Constants.selectedBackgroundColor

        setupThumbnail()
        setupMetadata()
    }

    private func setupThumbnail() {
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        contentView.addSubview(thumbnailView)
        thumbnailView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.uiPadding)
            make.left.equalToSuperview().offset(Constants.uiPadding)
            make.right.equalToSuperview().offset(-Constants.uiPadding)
            make.height.equalTo(thumbnailView.snp.width).multipliedBy(9.0/16.0)
        }

        // Add blur and image
        let thumbnailBlur = thumbnailView.blur(style: .light)
        thumbnailBlur.isHidden = true
        thumbnailBlur.reactive.isHidden <~ video.isPremium.map { !($0.value ?? false) }
        thumbnailView.reactive.setImage(options: [.transition(.fade(0.5))]) <~ video.thumbnailURL.map { $0.value }

        // Setup subviews
        setupLock()
        setupDurationView()
    }

    private func setupLock() {
        lockView.contentMode = .scaleAspectFit
        lockView.tintColor = Constants.backgroundColor
        thumbnailView.addSubview(lockView)
        lockView.snp.makeConstraints { make in
            make.center.equalTo(thumbnailView)
            make.height.equalTo(lockView.snp.width)
            make.height.equalTo(thumbnailView).dividedBy(5)
        }

        // Setup hide/show
        lockView.isHidden = true
        lockView.reactive.isHidden <~ video.isPremium.map { !($0.value ?? false) }
    }

    private func setupDurationView() {
        thumbnailView.addSubview(durationView)
        durationView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        durationView.label.reactive.text <~ video.duration.map { $0.value ?? "--:--" }
    }

    private func setupMetadata() {
        contentView.addSubview(metadataView)
        metadataView.snp.makeConstraints { make in
            make.top.equalTo(thumbnailView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(.high)
        }

        setupChannelIcon()
        setupTitles()
    }

    private func setupChannelIcon() {
        channelIconView.backgroundColor = UIColor.lightGray
        channelIconView.layer.cornerRadius = Constants.channelIconSize / 2
        channelIconView.layer.masksToBounds = false
        channelIconView.clipsToBounds = true
        metadataView.addSubview(channelIconView)
        channelIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.uiPadding)
            make.bottom.equalToSuperview().offset(Constants.uiPadding)
            make.left.equalToSuperview().offset(Constants.uiPadding)
            make.height.equalTo(Constants.channelIconSize)
            make.width.equalTo(Constants.channelIconSize)
        }

        // Add icon
        let iconURL = video.channel.get(\.thumbnailURL)
        channelIconView.reactive.setImage(options: [.transition(.fade(0.5))]) <~ iconURL.map { $0.value }
    }

    private func setupTitles() {
        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.alignment = .fill
        titleStackView.distribution = .equalSpacing
        titleStackView.axis = .vertical

        metadataView.addSubview(titleStackView)
        titleStackView.snp.makeConstraints { make in
            make.centerY.equalTo(channelIconView)
            make.left.equalTo(channelIconView.snp.right).offset(Constants.uiPadding)
            make.right.equalToSuperview()
        }

        setupTitle()
        setupSubtitle()
    }

    private func setupTitle() {
        titleLabel.font = UIFont.systemFont(ofSize: 13)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 2
        titleLabel.reactive.text <~ video.title.map { $0.value ?? "Loading ..." }
    }

    private func setupSubtitle() {
        subtitleLabel.font = UIFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.lineBreakMode = .byTruncatingTail

        // Setup data
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

        subtitleLabel.reactive.text <~ subtitle
    }
}
