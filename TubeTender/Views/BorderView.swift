//
//  BorderView.swift
//  TubeTender
//
//  Created by Noah Peeters on 06.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

enum BorderViewAxis {
    case horizontal
    case vertical
}

class BorderView: UIView {
    init(axis: BorderViewAxis) {
        super.init(frame: .zero)

        snp.makeConstraints { make in
            switch axis {
            case .horizontal:
                make.height.equalTo(1)
            case .vertical:
                make.width.equalTo(1)
            }
        }

        backgroundColor = Constants.borderColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
