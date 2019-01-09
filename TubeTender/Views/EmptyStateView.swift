//
//  EmptyStateView.swift
//  TubeTender
//
//  Created by Noah Peeters on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class EmptyStateView: UIView {
    init(image: UIImage, text: String) {
        super.init(frame: .zero)

        let descriptionLabel = UILabel()
        descriptionLabel.textColor = Constants.labelColor
        descriptionLabel.font = descriptionLabel.font.withSize(25)
        descriptionLabel.text = text
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.snp.centerY).offset(8)
        }

        let iconView = UIImageView()
        iconView.image = image
        iconView.tintColor = Constants.labelColor
        iconView.contentMode = .scaleAspectFit
        self.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.snp.centerY)
            make.height.equalTo(50)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
