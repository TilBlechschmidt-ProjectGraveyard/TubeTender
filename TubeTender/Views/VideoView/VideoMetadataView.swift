//
//  VideoMetadataView.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import DownloadButton
import UIKit

class VideoMetadataView: UIScrollView {
    let channelIconSize: CGFloat = Constants.smallChannelIconSize

    private let metaView = UIView()

    // Video detail
    private let detailView = UIView()
    let videoTitle = UILabel()
    let viewCount = UILabel()

    // Video detail buttons
    let detailButtonView = UIView()
    var downloadButtonView: UIView! {
        didSet {
            detailButtonView.addSubview(downloadButtonView)
            downloadButtonView.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        }
    }

    // Channel
    private let channelView = UIView()
    let channelThumbnail = UIImageView()
    let channelTitle = UILabel()
    let channelSubscriberCount = UILabel()

    // Description
    private let descriptionView = UIView()
    let videoDescriptionView = UITextView()

    public weak var videoMetadataViewDelegate: VideoMetadataViewDelegate?

    init() {
        super.init(frame: .zero)

        backgroundColor = Constants.backgroundColor
        autoresizingMask = [.flexibleHeight, .flexibleWidth]

        let stackView = UIStackView(arrangedSubviews: [
            setupVideoDetails(),
            BorderView(axis: .horizontal),
            setupChannelDetails(),
            BorderView(axis: .horizontal),
            setupVideoDescription()
        ])

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupVideoDetails() -> UIView {
        let innerStackView = UIStackView(arrangedSubviews: [videoTitle, viewCount])

        let rootStackView = UIStackView(arrangedSubviews: [
            innerStackView,
            detailButtonView
        ])

        rootStackView.distribution = .equalSpacing
        rootStackView.alignment = .center
        rootStackView.spacing = Constants.uiPadding

        innerStackView.axis = .vertical
        innerStackView.distribution = .fillEqually
        innerStackView.alignment = .leading
        innerStackView.spacing = Constants.uiPadding / 2

        videoTitle.font = videoTitle.font.withSize(13)
        videoTitle.textColor = UIColor.white
        videoTitle.lineBreakMode = .byTruncatingTail

        viewCount.font = viewCount.font.withSize(11)
        viewCount.textColor = UIColor.lightGray

        return InsetView(view: rootStackView)
    }

    func setupChannelDetails() -> UIView {
        let innerStackView = UIStackView(arrangedSubviews: [channelTitle, channelSubscriberCount])

        let rootStackView = UIStackView(arrangedSubviews: [
            channelThumbnail,
            innerStackView
        ])

        rootStackView.distribution = .fill
        rootStackView.alignment = .center
        rootStackView.spacing = Constants.uiPadding

        innerStackView.axis = .vertical
        innerStackView.distribution = .fillEqually
        innerStackView.alignment = .leading
        innerStackView.spacing = Constants.uiPadding / 4

        channelThumbnail.backgroundColor = UIColor.lightGray
        channelThumbnail.layer.cornerRadius = channelIconSize / 2
        channelThumbnail.layer.masksToBounds = false
        channelThumbnail.clipsToBounds = true
        channelThumbnail.kf.indicatorType = .activity
        channelThumbnail.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: channelIconSize, height: channelIconSize))
        }

        channelTitle.font = channelTitle.font.withSize(13)
        channelTitle.textColor = UIColor.white
        channelTitle.lineBreakMode = .byTruncatingTail

        channelSubscriberCount.font = channelTitle.font.withSize(11)
        channelSubscriberCount.textColor = UIColor.lightGray
        channelSubscriberCount.lineBreakMode = .byTruncatingTail

        return InsetView(view: rootStackView)
    }

    func setupVideoDescription() -> UIView {
        videoDescriptionView.font = videoDescriptionView.font?.withSize(12)
        videoDescriptionView.textColor = UIColor.lightGray
        videoDescriptionView.isEditable = false
        videoDescriptionView.dataDetectorTypes = .all
        videoDescriptionView.isScrollEnabled = false
        videoDescriptionView.backgroundColor = nil
        videoDescriptionView.delegate = self
        return InsetView(view: videoDescriptionView)
    }
}

extension VideoMetadataView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction, let delegate = videoMetadataViewDelegate {

            let beginning = textView.beginningOfDocument
            guard let center = textView.position(from: beginning, offset: characterRange.location + characterRange.length / 2) else { return true }

            let rect = textView.caretRect(for: center)

            return delegate.handle(url: URL, rect: rect, view: textView)
        }
        return true
    }
}

public protocol VideoMetadataViewDelegate: class {
    func handle(url: URL, rect: CGRect, view: UIView) -> Bool
}
