//
//  YoutubeClient.swift
//  TubeTender
//
//  Created by Noah Peeters on 06.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import YoutubeKit
import ReactiveSwift

class YoutubeClient {
    let apiSession = ApiSession.shared
}

enum TestError: Error {
    case test
}

public class YoutubeClientObject<APIResponse> {
    typealias FetchSignalProducer = SignalProducer<APIResponse, TestError>
    typealias FetchSignal = Signal<APIResponse, TestError>

    enum FetchStatus {
        case completed(value: APIResponse)
        case running(signal: FetchSignal)
        case notRunning
    }

    let client: YoutubeClient

//    private var fetchStatus = FetchStatus.notRunning
    private var apiResponse: Property<APIResponse>

    func fetchData<T: Requestable>(request: T) -> FetchSignalProducer {


        switch fetchStatus {
        case let .completed(value):
            return SignalProducer(value: value)
        case let .running(signal):
            return signal.producer
        case .notRunning:
            let producer = ApiSession.shared.reactive.send(request)
            self.fetchStatus = Signal(producer)
            return producer
        }


        if let apiResponse = apiResponse.value {
            return SignalProducer(value: apiResponse)
        }

        if isFetching {
            return apiResponse.producer.promoteError()
        }





        return SignalProducer(error: TestError.test)

//
//        return SignalProducer() { observable, disposable in
//
//            let a =  ApiSession.shared.reactive.send(request)
//
//            observable.send(a.start)
//        }
    }

    init(client: YoutubeClient) {
        self.client = client
    }
}
