//
//  SignalProducer+Cache.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 07.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import Result

class SignalProducerCache<Value, ErrorType: Error> {
    private var mutableProperty = MutableProperty<Result<Value, ErrorType>?>(nil)
    private var expirationDate: Date = Date()
    private var currentlyFetching: Bool = false

    private let signalProducerClosure: () -> SignalProducer<Value, ErrorType>
    private let lifetime: TimeInterval

    init(lifetime: TimeInterval, _ signalProducerClosure: @autoclosure @escaping () -> SignalProducer<Value, ErrorType>) {
        self.lifetime = lifetime
        self.signalProducerClosure = signalProducerClosure
    }

    func fetch() -> SignalProducer<Value, ErrorType> {
        // Value is not available and not fetching
        if !currentlyFetching && (mutableProperty.value == nil || Date() > expirationDate) {
            mutableProperty.value = nil
            currentlyFetching = true

            signalProducerClosure().startWithResult {
                self.currentlyFetching = false
                self.mutableProperty.value = $0
                self.expirationDate = Date(timeIntervalSinceNow: self.lifetime)
            }
        }

        return mutableProperty.producer.filterMap { $0 }.promoteError().attemptMap { $0 }
    }
}

extension SignalProducer {
    func cached(lifetime: TimeInterval) -> SignalProducer<Value, Error> {
        let cache = SignalProducerCache(lifetime: lifetime, self)

        return SignalProducer<SignalProducer<Value, Error>, NoError>() { observable, _ in
            observable.send(value: cache.fetch())
            }.flatten(.latest)
    }
}
