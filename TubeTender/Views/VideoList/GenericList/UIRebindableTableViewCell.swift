//
//  UIRebindableTableViewCell.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

class UIRebindableTableViewCell: UITableViewCell {
    private let disposable = SerialDisposable()
    private var disposeBag = CompositeDisposable()

    override func prepareForReuse() {
        disposeBindings()
    }

    func makeDisposableBindings(_ closure: (CompositeDisposable) -> Void) {
        if disposable.inner == nil {
            disposable.inner = disposeBag
        }
        closure(disposeBag)
    }

    func disposeBindings() {
        disposable.dispose()
        disposeBag = CompositeDisposable()
        disposable.inner = disposeBag
    }
}
