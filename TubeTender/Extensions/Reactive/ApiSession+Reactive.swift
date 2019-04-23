//
//  ApiSession+Reactive.swift
//  TubeTender
//
//  Created by Noah Peeters on 06.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveCocoa
import ReactiveSwift
import YoutubeKit

extension ApiSession: ReactiveExtensionsProvider {}

extension Reactive where Base: ApiSession {
    public func send<T: Requestable>(_ request: T) -> SignalProducer<T.Response, Error> {
        return SignalProducer { observer, lifetime in
            let task = self.base.send(request) { result in
                switch result {
                case .success(let response):
                    observer.send(value: response)
                    observer.sendCompleted()
                case .failed(let error):
                    observer.send(error: error)
                }
            }

            lifetime.observeEnded {
                task.cancel()
            }
        }
    }
}
