//
//  SNP+Frame.swift
//  TubeTender
//
//  Created by Noah Peeters on 06.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SnapKit
import UIKit

extension ConstraintViewDSL {
    func makeEdgesEqualToSuperview(inset: CGFloat = 0) {
        makeConstraints { make in
            make.edges.equalToSuperview().inset(inset)
        }
    }
}
