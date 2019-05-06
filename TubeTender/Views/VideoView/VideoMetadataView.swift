//
//  VideoMetadataView.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import DownloadButton
import UIKit

class VideoMetadataView: UIView {
    let channelIconSize: CGFloat = Constants.smallChannelIconSize

    private let metaScrollView = UIScrollView()
    private let metaView = UIView()

    // Video detail
    private let detailView = UIView()
    let videoTitle = UILabel()
    let viewCount = UILabel()

    // Video detail buttons
    let detailButtonView = UIView()
    var downloadButtonView: UIView! {
        didSet {
            downloadButtonView.translatesAutoresizingMaskIntoConstraints = false
            detailButtonView.addSubview(downloadButtonView)
            detailButtonView.addConstraints([
                downloadButtonView.rightAnchor.constraint(equalTo: detailButtonView.rightAnchor),
                downloadButtonView.centerYAnchor.constraint(equalTo: detailButtonView.centerYAnchor)
            ])
        }
    }

    // Channel
    private let channelView = UIView()
    var channelThumbnail = UIImageView()
    let channelTitle = UILabel()
    let channelSubscriberCount = UILabel()

    // Description
    private let descriptionView = UIView()
    let videoDescriptionView = UITextView()

    public weak var delegate: VideoMetadataViewDelegate?

    init() {
        super.init(frame: .zero)

        backgroundColor = Constants.backgroundColor // TODO This had .darker attached to it

        setupMetaScrollView()

        setupVideoDetails()
        setupChannelDetails()
        setupVideoDescription()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupMetaScrollView() {
        let metaScrollViewContainer = UIView()
        addSubview(metaScrollViewContainer)
        metaScrollViewContainer.translatesAutoresizingMaskIntoConstraints = false
        metaScrollViewContainer.clipsToBounds = true
        addConstraints([
            metaScrollViewContainer.topAnchor.constraint(equalTo: topAnchor),
            metaScrollViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            metaScrollViewContainer.widthAnchor.constraint(equalTo: widthAnchor)
        ])

        metaScrollViewContainer.addSubview(metaScrollView)

        metaScrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        metaScrollView.addSubview(metaView)
        metaView.translatesAutoresizingMaskIntoConstraints = false
        metaScrollView.addConstraints([
            metaView.topAnchor.constraint(equalTo: metaScrollView.topAnchor),
            metaView.bottomAnchor.constraint(equalTo: metaScrollView.bottomAnchor)
        ])
        metaScrollViewContainer.addConstraints([
            metaView.leadingAnchor.constraint(equalTo: metaScrollViewContainer.leadingAnchor),
            metaView.trailingAnchor.constraint(equalTo: metaScrollViewContainer.trailingAnchor)
        ])
    }

    func setupVideoDetails() {
        detailView.translatesAutoresizingMaskIntoConstraints = false
        metaView.addSubview(detailView)
        metaView.addConstraints([
            detailView.topAnchor.constraint(equalTo: metaView.topAnchor),
            detailView.leftAnchor.constraint(equalTo: metaView.leftAnchor),
            detailView.rightAnchor.constraint(equalTo: metaView.rightAnchor)
        ])

        videoTitle.font = videoTitle.font.withSize(13)
        videoTitle.textColor = UIColor.white
        videoTitle.lineBreakMode = .byTruncatingTail
        detailView.addSubview(videoTitle)
        videoTitle.translatesAutoresizingMaskIntoConstraints = false
        detailView.addConstraints([
            videoTitle.topAnchor.constraint(equalTo: detailView.topAnchor, constant: Constants.uiPadding),
            videoTitle.leftAnchor.constraint(equalTo: detailView.leftAnchor, constant: Constants.uiPadding)
        ])

        viewCount.font = viewCount.font.withSize(11)
        viewCount.textColor = UIColor.lightGray
        detailView.addSubview(viewCount)
        viewCount.translatesAutoresizingMaskIntoConstraints = false
        detailView.addConstraints([
            viewCount.topAnchor.constraint(equalTo: videoTitle.bottomAnchor, constant: Constants.uiPadding / 2),
            viewCount.leftAnchor.constraint(equalTo: videoTitle.leftAnchor),
            viewCount.rightAnchor.constraint(equalTo: videoTitle.rightAnchor),
            viewCount.bottomAnchor.constraint(equalTo: detailView.bottomAnchor, constant: -Constants.uiPadding)
        ])

        detailButtonView.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(detailButtonView)
        detailView.addConstraints([
            detailButtonView.topAnchor.constraint(equalTo: detailView.topAnchor, constant: Constants.uiPadding),
            detailButtonView.leftAnchor.constraint(equalTo: videoTitle.rightAnchor, constant: Constants.uiPadding),
            detailButtonView.rightAnchor.constraint(equalTo: detailView.rightAnchor, constant: -Constants.uiPadding),
            detailButtonView.bottomAnchor.constraint(equalTo: detailView.bottomAnchor, constant: -Constants.uiPadding)
        ])
    }

    //swiftlint:disable:next function_body_length
    func setupChannelDetails() {
        metaView.addSubview(channelView)
        channelView.snp.makeConstraints { make in
            make.top.equalTo(detailView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        let topBorder = UIView()
        topBorder.backgroundColor = Constants.borderColor
        channelView.addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(1)
        }

        let bottomBorder = UIView()
        bottomBorder.backgroundColor = Constants.borderColor
        channelView.addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(1)
        }

        channelThumbnail.backgroundColor = UIColor.lightGray
        channelThumbnail.layer.cornerRadius = channelIconSize / 2
        channelThumbnail.layer.masksToBounds = false
        channelThumbnail.clipsToBounds = true
        channelThumbnail.kf.indicatorType = .activity
        channelView.addSubview(channelThumbnail)
        channelThumbnail.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: channelIconSize, height: channelIconSize))
            make.top.equalToSuperview().offset(Constants.uiPadding)
            make.left.equalToSuperview().offset(Constants.uiPadding)
            make.bottom.equalToSuperview().offset(-Constants.uiPadding)
        }

        let channelDetailLabelView = UIView()
        channelView.addSubview(channelDetailLabelView)
        channelDetailLabelView.snp.makeConstraints { make in
            make.centerY.equalTo(channelThumbnail)
            make.left.equalTo(channelThumbnail.snp.right).offset(Constants.uiPadding)
            make.right.equalToSuperview().offset(-Constants.uiPadding)
        }

        channelTitle.font = channelTitle.font.withSize(13)
        channelTitle.textColor = UIColor.white
        channelTitle.lineBreakMode = .byTruncatingTail
        channelDetailLabelView.addSubview(channelTitle)
        channelTitle.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
        }

        channelSubscriberCount.font = channelTitle.font.withSize(11)
        channelSubscriberCount.textColor = UIColor.lightGray
        channelSubscriberCount.lineBreakMode = .byTruncatingTail
        channelDetailLabelView.addSubview(channelSubscriberCount)
        channelSubscriberCount.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(channelTitle.snp.bottom).offset(Constants.uiPadding / 4)
        }
    }

    func setupVideoDescription() {
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        metaView.addSubview(descriptionView)
        metaView.addConstraints([
            descriptionView.topAnchor.constraint(equalTo: channelView.bottomAnchor),
            descriptionView.leftAnchor.constraint(equalTo: metaView.leftAnchor),
            descriptionView.rightAnchor.constraint(equalTo: metaView.rightAnchor),
            descriptionView.bottomAnchor.constraint(equalTo: metaView.bottomAnchor)
        ])

        videoDescriptionView.font = videoDescriptionView.font?.withSize(12)
        videoDescriptionView.textColor = UIColor.lightGray
        videoDescriptionView.isEditable = false
        videoDescriptionView.dataDetectorTypes = .all
        videoDescriptionView.isScrollEnabled = false
        videoDescriptionView.backgroundColor = nil
        videoDescriptionView.delegate = self
        videoDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        descriptionView.addSubview(videoDescriptionView)
        descriptionView.addConstraints([
            videoDescriptionView.topAnchor.constraint(equalTo: descriptionView.topAnchor, constant: Constants.uiPadding),
            videoDescriptionView.leftAnchor.constraint(equalTo: descriptionView.leftAnchor, constant: Constants.uiPadding),
            videoDescriptionView.rightAnchor.constraint(equalTo: descriptionView.rightAnchor, constant: -Constants.uiPadding),
            videoDescriptionView.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: -Constants.uiPadding)
        ])
    }
}

extension VideoMetadataView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction, let delegate = delegate {

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
