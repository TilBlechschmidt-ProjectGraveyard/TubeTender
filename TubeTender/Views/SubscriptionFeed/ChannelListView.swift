//
//  ChannelListView.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 05.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

class ChannelListView: UIView {
    private let compact: Bool

    var channels: [Channel] = [] {
        didSet {
            reloadData()
        }
    }

    init(compact: Bool = true) {
        self.compact = compact
        super.init(frame: .zero)

        if compact {
            backgroundColor = UIColor.white.withAlphaComponent(0.5)
        } else {
            backgroundColor = Constants.backgroundColor
        }

        blur(style: .regular)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadData() {
        subviews.forEach { $0.removeFromSuperview() }

        let channelViews = channels.map { ChannelListEntryView(channel: $0, compact: compact) }
        let stackView = UIStackView(arrangedSubviews: channelViews)
        let scrollView = UIScrollView()

        stackView.spacing = Constants.uiPadding

        if !compact {
            stackView.axis = .vertical
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Constants.uiPadding)
            make.left.equalToSuperview().inset(Constants.uiPadding)
            make.right.equalToSuperview().inset(Constants.uiPadding)
            make.bottom.equalToSuperview().inset(Constants.uiPadding)

            if compact {
                make.height.equalToSuperview().offset(-2 * Constants.uiPadding)
            } else {
                make.width.equalToSuperview().offset(-2 * Constants.uiPadding)
            }
        }

        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }

        scrollView.contentInsetAdjustmentBehavior = .always

        blur(style: .regular)
    }
}

class ChannelListEntryView: UIStackView {
    convenience init(channel: Channel, compact: Bool = true) {
        let iconView = UIImageView()
        let nameLabel = UILabel()

        iconView.reactive.setImage(options: [.transition(.fade(0.5))]) <~ channel.thumbnailURL.map { $0.value }

        iconView.backgroundColor = Constants.selectedBackgroundColor
        iconView.layer.cornerRadius = Constants.channelIconSize / 2
        iconView.layer.masksToBounds = false
        iconView.clipsToBounds = true

        iconView.snp.makeConstraints { make in
            make.height.equalTo(Constants.channelIconSize)
            make.width.equalTo(Constants.channelIconSize)
        }

        if !compact {
            nameLabel.textColor = .white
            nameLabel.reactive.text <~ channel.title.map { $0.value }
        }

        self.init(arrangedSubviews: [iconView] + (compact ? [] : [nameLabel]))
        spacing = Constants.uiPadding
    }
}
