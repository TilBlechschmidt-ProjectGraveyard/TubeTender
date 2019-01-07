//
//  Kingfisher+Reactive.swift
//  TubeTender
//
//  Created by Noah Peeters on 07.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import Kingfisher
import ReactiveCocoa
import ReactiveSwift
import Result

extension Reactive where Base: UIImageView {
    public func setImage(placeholder: Placeholder? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil) -> BindingTarget<Resource?> {
        return makeBindingTarget { imageView, imageResource in
            imageView.kf.setImage(
                with: imageResource,
                placeholder: placeholder,
                options: options,
                progressBlock: progressBlock)
        }
    }
}
