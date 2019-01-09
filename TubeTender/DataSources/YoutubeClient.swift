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

    var channelCache: [Channel.ID : Channel] = [:]
    var videoCache: [Video.ID : Video] = [:]

    init(apiSession: ApiSession = ApiSession.shared) {
        self.apiSession = apiSession
    }

    func cacheOrCreate<I, T>(_ id: I, _ cache: inout [I : T], _ create: @autoclosure () -> T) -> T {
        if let item = cache[id] {
            return item
        } else {
            let item = create()
            cache[id] = item
            return item
        }
    }
}

enum YoutubeClientObjectError: Swift.Error {
    case invalidAPIResponse
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

    func makeProperty<T>(_ mapper: @escaping (DataType) -> T?) -> APISignalProducer<T> {
        return response.tryMap(YoutubeClientObjectError.invalidAPIResponse, mapper)
    }

    func prefetchData() {
        response.start()
    }
}

extension YoutubeClientObject where Request.Response == DataType {
    convenience init(client: YoutubeClient, request: Request) {
        self.init(client: client, request: request, mapResponse: { $0 })
    }
}
