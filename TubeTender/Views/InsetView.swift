//
//  InsetView.swift
//  TubeTender
//
//  Created by Noah Peeters on 06.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class InsetView: UIView {
    init(view: UIView, insets: UIEdgeInsets) {
        super.init(frame: .zero)
        addSubview(view)

        view.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(insets.left)
            make.top.equalToSuperview().inset(insets.top)
            make.right.equalToSuperview().inset(insets.right)
            make.bottom.equalToSuperview().inset(insets.bottom)
        }
    }

    convenience init(view: UIView, equalInsets inset: CGFloat = Constants.uiPadding) {
        self.init(view: view, insets: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
