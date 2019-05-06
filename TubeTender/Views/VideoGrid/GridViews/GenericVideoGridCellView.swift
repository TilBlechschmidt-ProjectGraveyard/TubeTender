//
//  GenericVideoGridCellView.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 05.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class GenericVideoGridCellView: UICollectionViewCell {
    static let identifier: String = "GenericVideoGridViewCell"

    let videoCellView = VideoCellView(borderlessThumbnail: UIDevice.current.userInterfaceIdiom == .phone)

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

    override init(frame: CGRect) {
        super.init(frame: frame)

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
