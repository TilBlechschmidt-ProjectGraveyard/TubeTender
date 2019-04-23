//
//  CocoaAction+Closure.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 08.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveCocoa
import ReactiveSwift
import Result

extension CocoaAction {
    convenience init(action: @escaping (Sender) -> Void) {
        let wrappedAction = Action<Sender, Never, AnyError> { input in
            return SignalProducer { _, _ in action(input) }
        }
        self.init(wrappedAction) { $0 }
    }

    convenience init(action: @autoclosure @escaping () -> Void) {
        self.init { _ in
            action()
        }
    }
}
