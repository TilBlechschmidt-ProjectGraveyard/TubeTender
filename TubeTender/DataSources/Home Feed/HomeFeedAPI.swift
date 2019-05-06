//
//  HomeFeedAPI.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 02.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift

enum HomeFeedAPIError: Error {
    case noContinuationAvailable
    case invalidResponse
}

class HomeFeedAPI {
    static let userAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Safari/605.1.15"
    private static let dataPrefix: String = "    window[\"ytInitialData\"] = "
    private static let youtubeClientVersion: String = "2.20190423"
    private static let youtubeClientName: String = "1"

    let cookies: [HTTPCookie]

    var identityToken: String?
    var continuationToken: String?

    var canContinue: Bool {
        return continuationToken != nil
    }

    init(cookies: [HTTPCookie]) {
        self.cookies = cookies
    }

    func clearContinuationData() {
        continuationToken = nil
    }

    func fetchHomeFeed() -> SignalProducer<[HomeFeedDataSection], Error> {
        var request = URLRequest(url: URL(string: "https://www.youtube.com/")!)

        let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
        request.allHTTPHeaderFields = cookieHeaders
        request.addValue(HomeFeedAPI.userAgent, forHTTPHeaderField: "User-Agent")

        let session = URLSession(configuration: .ephemeral)

        return SignalProducer { observer, _ in
            session.dataTask(with: request) { data, _, error in
                if let data = data, let html = String(data: data, encoding: .utf8) {
                    self.identityToken = self.identityToken(from: html)

                    let initialDataLine = html.components(separatedBy: "\n").filter { $0.contains("ytInitialData") }.first!
                    let homeFeedData = initialDataLine.prefix(initialDataLine.count - 1).replacingOccurrences(of: HomeFeedAPI.dataPrefix, with: "")

                    do {
                        let feed = try JSONDecoder().decode(HomeFeedData.self, from: homeFeedData.data(using: .utf8)!)
                        self.continuationToken = feed.continuation.token
                        observer.send(value: feed.sections)
                        observer.sendCompleted()
                    } catch {
                        observer.send(error: error)
                    }
                } else if let error = error {
                    observer.send(error: error)
                }
            }.resume()
        }
    }

    func fetchHomeFeedContinuation() -> SignalProducer<[HomeFeedDataSection], Error> {
        guard let identityToken = identityToken, let continuationToken = continuationToken else {
            return SignalProducer(error: HomeFeedAPIError.noContinuationAvailable)
        }

        // TODO When unauthenticated / authentication is invalid continuation contains the initial data. Bail out.

        let url = URL(string: "https://www.youtube.com/browse_ajax?ctoken=\(continuationToken)") //"&continuation=\(continuationToken)")
        var request = URLRequest(url: url!)

        let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
        request.allHTTPHeaderFields = cookieHeaders
        request.addValue(HomeFeedAPI.userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue(HomeFeedAPI.youtubeClientName, forHTTPHeaderField: "X-YouTube-Client-Name")
        request.addValue(HomeFeedAPI.youtubeClientVersion, forHTTPHeaderField: "X-YouTube-Client-Version")
        request.addValue(identityToken, forHTTPHeaderField: "X-Youtube-Identity-Token")

        let session = URLSession(configuration: .ephemeral)

        return SignalProducer { observer, _ in
            session.dataTask(with: request) { data, response, error in

                // TODO Make use of Set-Cookies response header to refresh the cookies

                if let data = data, let json = String(data: data, encoding: .utf8) {
                    do {
                        let feed = try JSONDecoder().decode(HomeFeedContinuationData.self, from: json.data(using: .utf8)!)
                        self.continuationToken = feed.continuation.token
                        observer.send(value: feed.sections)
                        observer.sendCompleted()
                    } catch {
                        observer.send(error: error)
                    }
                } else if let error = error {
                    observer.send(error: error)
                } else {
                    observer.send(error: HomeFeedAPIError.invalidResponse)
                }
            }.resume()
        }
    }

    private func identityToken(from html: String) -> String? {
        return SimpleRegexMatcher.firstMatch(forPattern: "\"ID_TOKEN\": ?\"(.*?)\"", in: html)?.groups[1].flatMap(String.init)
    }
}
