//
//  Alamofire+Reactive.swift
//  TubeTender
//
//  Created by Noah Peeters on 20.05.18.
//  Copyright © 2018 Noah Peeters. All rights reserved.
//

import Alamofire
import ReactiveSwift

/// Queue used for alamofire completion handler.
private let alamofireQueue = DispatchQueue(label: "Alamofire queue")

public enum DataRequestError: LocalizedError {
    case serverUnreachable
    case stringDecodeError(data: Data)
    case httpStatusCodeFailed(data: Data?, statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .serverUnreachable:
            return "Server unreachable."
        case .stringDecodeError:
            return "String decoding error."
        case .httpStatusCodeFailed(let data, let statusCode):
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Received status code \(statusCode)"
        }
    }
}

extension DataRequest {
    internal func signalProducer(onlyAcceptsHTTPOK: Bool = false) -> SignalProducer<Data, Error> {
        return SignalProducer { observer, lifetime in
            self.response(queue: alamofireQueue) { response in
                guard !onlyAcceptsHTTPOK || response.response?.statusCode == 200 else {
                    observer.send(error: DataRequestError.httpStatusCodeFailed(data: response.data, statusCode: response.response?.statusCode ?? -1)
                    )
                    return
                }

                guard response.response != nil else {
                    observer.send(error: DataRequestError.serverUnreachable)
                    return
                }

                if let data = response.data {
                    observer.send(value: data)
                    observer.sendCompleted()
                } else {
                    observer.send(error: response.error!)
                }
            }

            lifetime.observeEnded(self.cancel)
        }
    }

    internal func stringSignalProducer(encoding: String.Encoding = .utf8, onlyAcceptsHTTPOK: Bool = false) -> SignalProducer<String, Error> {
        return signalProducer(onlyAcceptsHTTPOK: onlyAcceptsHTTPOK).attemptMap { data in
            if let text = String(data: data, encoding: encoding) {
                return text
            } else {
                throw DataRequestError.stringDecodeError(data: data)
            }
        }
    }

    internal func jsonSignalProducer<ResponseType: Decodable>(type: ResponseType.Type)
        -> SignalProducer<ResponseType, Error> {
            return signalProducer().attemptMap { data in
                let jsonDecoder = JSONDecoder()
                return try jsonDecoder.decode(ResponseType.self, from: data)
            }
    }
}
