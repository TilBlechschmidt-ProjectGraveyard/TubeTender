//
//  ButtonStackView.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 11.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class ButtonStackView: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.blur(style: .dark, cornerRadius: 10, corners: nil)

        let spacing = Constants.uiPadding / 1.25
        self.spacing = spacing
        self.isLayoutMarginsRelativeArrangement = true
        self.layoutMargins = UIEdgeInsets(top: spacing,
                                          left: spacing,
                                          bottom: spacing,
                                          right: spacing)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
