//
//  SubscriptionFeedTableCell.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Kingfisher
import ReactiveSwift
import SnapKit
import UIKit

class SubscriptionFeedViewTableCell: UIRebindableTableViewCell {
    static let identifier = "SubscriptionFeedViewTableCell"

    let thumbnailView = UIImageView()
    let durationView = DurationView()
    let lockView = UIImageView(image: #imageLiteral(resourceName: "lock"))

    let metadataView = UIView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let channelIconView = UIImageView()

    var thumbnailBlur: UIVisualEffectView!

    var video: Video! {
        didSet {
            thumbnailView.image = nil
            makeBindings()
        }
    }

    var hideThumbnail: Bool = false {
        didSet {
            thumbnailView.isHidden = hideThumbnail
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeBindings() {
        let iconURL = video.channel.get(\.thumbnailURL)

        let stringDuration = video.durationString.map { $0.value ?? "--:--" }

        let subtitleData = SignalProducer.zip(
            video.channelTitle.map { $0.value },
            video.viewCount.map { $0.value },
            video.published.map { $0.value },
            video.isPremium.map { $0.value },
            stringDuration
        )

        let subtitle: SignalProducer<String, Never> = subtitleData.map { [unowned self] data in
            let (channelTitle, viewCount, published, isPremium, duration) = data

            let displayData = [
                channelTitle ?? "Loading ...",
                (isPremium ?? false) ? "Premium Content" : viewCount.map { "\($0.withThousandSeparators) views" },
                published?.since(),
                self.hideThumbnail ? duration : nil
            ]

            return displayData.compactMap { $0 }.joined(separator: " ∙ ")
        }

        makeDisposableBindings { bindings in
            if !hideThumbnail {
                bindings += thumbnailBlur.reactive.isHidden <~ video.isPremium.map { !($0.value ?? false) }
                bindings += thumbnailView.reactive.setImage(options: [.transition(.fade(0.5))]) <~ video.thumbnailURL.map { $0.value }
                bindings += lockView.reactive.isHidden <~ video.isPremium.map { !($0.value ?? false) }
                bindings += durationView.label.reactive.text <~ stringDuration
            }

            bindings += channelIconView.reactive.setImage(options: [.transition(.fade(0.5))]) <~ iconURL.map { $0.value }
            bindings += titleLabel.reactive.text <~ video.title.map { $0.value ?? "Loading ..." }
            bindings += subtitleLabel.reactive.text <~ subtitle
        }
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
        thumbnailBlur = thumbnailView.blur(style: .light)
        thumbnailBlur.isHidden = true

        // Setup subviews
        setupLock()
        setupDurationView()
    }

    private func setupLock() {
        lockView.contentMode = .scaleAspectFit
        lockView.tintColor = Constants.backgroundColor
        lockView.isHidden = true
        thumbnailView.addSubview(lockView)
        lockView.snp.makeConstraints { make in
            make.center.equalTo(thumbnailView)
            make.height.equalTo(lockView.snp.width)
            make.height.equalTo(thumbnailView).dividedBy(5)
        }
    }

    private func setupDurationView() {
        thumbnailView.addSubview(durationView)
        durationView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func setupMetadata() {
        contentView.addSubview(metadataView)
        metadataView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
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
            make.bottom.equalToSuperview().offset(-Constants.uiPadding)
            make.left.equalToSuperview().offset(Constants.uiPadding)
            make.height.equalTo(Constants.channelIconSize)
            make.width.equalTo(Constants.channelIconSize)
        }
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
    }

    private func setupSubtitle() {
        subtitleLabel.font = UIFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.lineBreakMode = .byTruncatingTail
    }
}
