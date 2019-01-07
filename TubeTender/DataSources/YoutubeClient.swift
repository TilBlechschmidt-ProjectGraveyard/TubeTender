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
    typealias ResponseMapper = (APISignalProducer<Request.Response>) -> APISignalProducer<DataType>

    let client: YoutubeClient
    let response: APISignalProducer<DataType>

    init(client: YoutubeClient, request: Request, mapResponse: ResponseMapper) {
        self.client = client

        let cachedResponse = client.apiSession.reactive
            .send(request)
            .cached(lifetime: Constants.cacheLifetime)

        response = mapResponse(cachedResponse)
    }
}

extension YoutubeClientObject where Request.Response == DataType {
    convenience init(client: YoutubeClient, request: Request) {
        self.init(client: client, request: request, mapResponse: { $0 })
    }
}
