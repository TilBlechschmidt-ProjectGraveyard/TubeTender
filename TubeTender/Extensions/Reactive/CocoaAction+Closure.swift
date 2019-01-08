//
//  CocoaAction+Closure.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 08.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Result
import ReactiveSwift
import ReactiveCocoa

extension CocoaAction {
    convenience init(action: @escaping (Sender) -> ()) {
        let a = Action<Sender, Never, AnyError> { input in
            print("creating signal producer")
            return SignalProducer() { _, _ in action(input) }
        }
        self.init(a, { $0 })
    }

    convenience init(action: @autoclosure @escaping () -> ()) {
        self.init(action: { _ in
            print("executing action")
            action()
        })
    }
}
