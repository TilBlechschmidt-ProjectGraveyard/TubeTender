//
//  DurationView.swift
//  TubeTender
//
//  Created by Noah Peeters on 08.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

public class DurationView: UIView {
    public let label = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addBlur()
        setupLabel()
    }

    private func addBlur() {
        self.blur(style: .dark, cornerRadius: 10, corners: [.layerMinXMinYCorner])
    }

    private func setupLabel() {
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        self.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalToSuperview().offset(-Constants.uiPadding)
            make.width.equalToSuperview().offset(-Constants.uiPadding)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
