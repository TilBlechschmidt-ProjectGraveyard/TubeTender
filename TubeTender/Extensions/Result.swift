//
//  Result.swift
//  TubeTender
//
//  Created by Noah Peeters on 07.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift

typealias APIResult<Value> = Result<Value, Swift.Error>
typealias APISignalProducer<Value> = SignalProducer<APIResult<Value>, Never>
typealias APIValueSignalProducer<Value> = SignalProducer<Value, Never>

extension Result where Failure == Swift.Error {
    func tryMap<NewSuccess>(mapper: @escaping (Success) throws -> NewSuccess) -> Result<NewSuccess, Swift.Error> {
        return self.flatMap {
            do {
                return try Result<NewSuccess, Failure>.success(mapper($0))
            } catch {
                return Result<NewSuccess, Failure>(failure: error)
            }
        }
    }
}

extension SignalProducer where Error == Never {
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
                return APISignalProducer(value: APIResult(failure: error))
            }
        }
    }

    func get<T, U>(_ path: KeyPath<T, APISignalProducer<U>>) -> APISignalProducer<U> where Value == APIResult<T> {
        return self.chain { object in
            object[keyPath: path]
        }
    }
}
