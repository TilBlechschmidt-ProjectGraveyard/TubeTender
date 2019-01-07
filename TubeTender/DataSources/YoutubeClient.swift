//
//  YoutubeClient.swift
//  TubeTender
//
//  Created by Noah Peeters on 06.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import YoutubeKit
import Result
import ReactiveSwift

class YoutubeClient {
    static let shared = YoutubeClient()

    let apiSession: ApiSession

    init(apiSession: ApiSession = ApiSession.shared) {
        self.apiSession = apiSession
    }
}

public class YoutubeClientObject<Request: Requestable, DataType> {
    typealias ResponseMapper = (SignalProducer<Request.Response, AnyError>) -> SignalProducer<DataType, AnyError>

    let client: YoutubeClient
    let response: SignalProducer<DataType, NoError>

    private let _error: MutableProperty<AnyError?>
    let error: Property<AnyError?>

    init(client: YoutubeClient, request: Request, mapResponse: ResponseMapper) {
        self.client = client

        let _error = MutableProperty<AnyError?>(nil)
        self._error = _error
        error = Property(_error)

        let cachedResponse = client.apiSession.reactive
            .send(request)
            .cached(lifetime: Constants.cacheLifetime)
            .on(value: { _ in _error.value = nil })

        response = mapResponse(cachedResponse).flatMapError {
            _error.value = $0
            return .empty
        }
    }
}

extension YoutubeClientObject where Request.Response == DataType {
    convenience init(client: YoutubeClient, request: Request) {
        self.init(client: client, request: request, mapResponse: { $0 })
    }
}
