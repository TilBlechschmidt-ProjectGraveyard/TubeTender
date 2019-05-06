//
//  GenericVideoGridHeaderView.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 05.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import SnapKit

class GenericVideoGridHeaderView: UICollectionReusableView {
    static let kind: String = "GenericTitle"
    static let identifier: String = "GenericVideoGridSupplimentaryView"

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let iconView = UIImageView()

    var iconVisibleConstraint: Constraint!
    var iconHiddenConstraint: Constraint!

    var blurView: UIVisualEffectView!

    var icon: URL? {
        didSet {
            iconView.image = nil
            iconView.kf.cancelDownloadTask()
            iconView.kf.setImage(with: icon)

            if icon == nil {
                iconVisibleConstraint.deactivate()
                iconHiddenConstraint.activate()
            } else {
                iconHiddenConstraint.deactivate()
                iconVisibleConstraint.activate()
            }
        }
    }

    var title: String! {
        didSet {
            titleLabel.text = title
        }
    }

    var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    func setupUI() {
        blurView = blur(style: .dark)

        titleLabel.textColor = .white

        subtitleLabel.textColor = Constants.borderColor
        subtitleLabel.font = subtitleLabel.font.withSize(14)

        iconView.layer.cornerRadius = Constants.channelIconSize / 2
        iconView.layer.masksToBounds = false
        iconView.clipsToBounds = true

        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.axis = .vertical

        let stackView = UIStackView(arrangedSubviews: [iconView, titleStackView])
        stackView.spacing = Constants.uiPadding
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
            make.left.equalToSuperview().offset(Constants.uiPadding)
        }

        iconView.snp.makeConstraints { make in
            make.height.equalTo(Constants.channelIconSize)
        }

        iconView.snp.prepareConstraints { make in
            iconVisibleConstraint = make.width.equalTo(Constants.channelIconSize).constraint
            iconHiddenConstraint = make.width.equalTo(0).constraint
        }

        iconHiddenConstraint.activate()
    }
}

