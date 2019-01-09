//
//  UIAlertController+Reactive.swift
//  TubeTender
//
//  Created by Noah Peeters on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift

extension Reactive where Base: UIAlertController {
    var message: BindingTarget<String?> {
        return makeBindingTarget(on: QueueScheduler.main) { alertController, message in
            alertController.message = message
        }
    }

    var attributedTitle: BindingTarget<NSAttributedString?> {
        return makeBindingTarget(on: QueueScheduler.main) { alertController, attributedTitle in
            alertController.setValue(attributedTitle, forKey: "attributedTitle")
        }
    }
}
