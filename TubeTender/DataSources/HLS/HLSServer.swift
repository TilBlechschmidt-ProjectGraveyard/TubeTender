//
//  HLSServer.swift
//  HLSServer
//
//  Created by Til Blechschmidt on 20.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import Result
import Network

class HLSServer {
    let listener: NWListener
    let hlsBuilder = HLSBuilder()

    init(port: UInt16) throws {
        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(integerLiteral: port))
    }

    func response(status: String, contentType: String = "application/vnd.apple.mpegurl", contentLength: Int = 0, body: String = "") -> String {
        return """
        HTTP/1.1 \(status)\r
        Date: Thu, 20 May 2018 21:20:58 GMT\r
        Connection: close\r
        Content-Type: \(contentType)\r
        Content-Length: \(contentLength)\r
        \r
        \(body)
        """
    }

    func notFound() -> SignalProducer<String, AnyError> {
        return SignalProducer(value: response(status: "404 Not Found", contentType: "text/html"))
    }

    func badRequest(_ reason: String = "") -> SignalProducer<String, AnyError> {
        return SignalProducer(value: response(status: "400 Bad Request", contentType: "text/html"))
    }

    func process(headers: [String]) -> [String: String] {
        return headers.reduce(into: [:]) { (acc, field) in
            let keyValue = field.components(separatedBy: ": ")
            if keyValue.count == 2 {
                acc[keyValue[0]] = keyValue[1]
            }
        }
    }

    func process(httpRequest request: String) -> SignalProducer<String, AnyError> {
        let parts = request.components(separatedBy: "\r\n\r\n")
        guard parts.count > 0 else { return badRequest("Invalid HTTP request") }
        var headers = parts[0].components(separatedBy: "\r\n")

        let requestSpecification = headers[0].components(separatedBy: " ")
        headers.remove(at: 0)
        guard requestSpecification.count == 3 else { return badRequest("Invalid HTTP request") }

        let url = requestSpecification[1]
        let urlParts = url.components(separatedBy: "/")

        if urlParts.count == 3 && urlParts[2].hasSuffix(".m3u8") {
            // Playlist m3u8
            let videoID = urlParts[1]
            let itag = urlParts[2].dropLast(5)

            return hlsBuilder.playlist(forVideoID: videoID, itag: String(itag)).map {
                self.response(status: "200 OK", contentLength: $0.count, body: $0)
            }
        } else if urlParts.count == 2 && urlParts[1].hasSuffix(".m3u8") {
            // Master m3u8
            let videoID = urlParts[1].dropLast(5)

            return hlsBuilder.masterPlaylist(forVideoID: String(videoID)).map {
                self.response(status: "200 OK", contentLength: $0.count, body: $0)
            }
        } else {
            // Should rather be 404
            return notFound()
        }
    }

    func listen(onQueue queue: DispatchQueue = DispatchQueue.global()) {
        let maximumReceiveLength = 1000

        listener.newConnectionHandler = { connection in
            connection.receive(minimumIncompleteLength: 10, maximumLength: maximumReceiveLength) { data, contentContext, bool, error in
                guard let data = data, let request = String(data: data, encoding: .utf8) else { return }

                self.process(httpRequest: request).startWithResult { result in
                    let res = result.value ?? self.response(status: "500 Internal Server Error", contentType: "text/html")
                    connection.send(content: res.data(using: .utf8), completion: .idempotent)
                }
            }
            connection.start(queue: DispatchQueue.global())
        }

        listener.start(queue: queue)
    }
}
