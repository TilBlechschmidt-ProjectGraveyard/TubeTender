//
//  SubscriptionFeedTableCell.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SnapKit
import UIKit

class SubscriptionFeedViewTableCell: UIRebindableTableViewCell {
    static let identifier = "SubscriptionFeedViewTableCell"

    let videoCellView = VideoCellView()

    var video: Video! {
        didSet {
            videoCellView.video = video
        }
    }

    var hideThumbnail: Bool = false {
        didSet {
            videoCellView.hideThumbnail = hideThumbnail
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = Constants.selectedBackgroundColor

        addSubview(videoCellView)
        videoCellView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
