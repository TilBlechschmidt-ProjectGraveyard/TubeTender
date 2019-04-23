//
//  Result.swift
//  TubeTender
//
//  Created by Noah Peeters on 07.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import Result

typealias APIResult<Value> = Result<Value, AnyError>
typealias APISignalProducer<Value> = SignalProducer<APIResult<Value>, NoError>
typealias APIValueSignalProducer<Value> = SignalProducer<Value, NoError>

extension SignalProducer where Error == NoError {
    func tryMap<T, U, E: Swift.Error>(_ error: E, _ mapper: @escaping (T) -> U?) -> APISignalProducer<U> where Value == APIResult<T> {
        return self.map { value in
            value.tryMap {
                return try mapper($0).unwrap(error)
            }
        }
    }

    func chain<T, U>(_ mapper: @escaping (T) -> APISignalProducer<U>) -> APISignalProducer<U> where Value == APIResult<T> {
        return self.flatMap(FlattenStrategy.latest) { result in
            switch result {
            case let .success(value):
                return mapper(value)
            case let .failure(error):
                return APISignalProducer(value: APIResult(error: error))
            }
        }
    }

    func get<T, U>(_ path: KeyPath<T, APISignalProducer<U>>) -> APISignalProducer<U> where Value == APIResult<T> {
        return self.chain { object in
            object[keyPath: path]
        }
    }
}
