//
//  VideoInfoAPI.swift
//  Pivo
//
//  Created by Til Blechschmidt on 04.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation
import ReactiveSwift

enum VideoInfoAPIError: Error {
    case invalidRequestURL
    case invalidResponse
}

typealias StreamCollection = (mixed: [StreamMetadata], video: [StreamMetadata], audio: [StreamMetadata])

final class VideoInfoAPI {
    fileprivate static let videoInfoPath = "https://www.youtube.com/get_video_info?video_id=%@&asv=3&el=detailpage&ps=default&hl=en_US"

    static let shared = VideoInfoAPI()

    private init() {}

    func streamManager(forVideoID videoID: String) -> SignalProducer<VideoStreamManager, VideoInfoAPIError> {
        return self.streams(forVideoID: videoID).map { VideoStreamManager(withStreams: $0) }
    }

    func streams(forVideoID videoID: String) -> SignalProducer<StreamCollection, VideoInfoAPIError> {
        return SignalProducer { observer, _ in
            // Build the request URL
            let path = String(format: VideoInfoAPI.videoInfoPath, videoID)
            guard let url = URL(string: path) else {
                observer.send(error: .invalidRequestURL)
                return
            }

            // Build the request
            var req = URLRequest(url: url)
            req.addValue("en", forHTTPHeaderField: "Accept-Language")

            // Send the request
            let session = URLSession(configuration: URLSessionConfiguration.default)
            session.dataTask(with: req) { data, response, error in
                // Convert the response to a string
                guard let data = data, data.count > 0, let urlParameters = String(data: data, encoding: .utf8) else {
                    observer.send(error: .invalidResponse)
                    return
                }

                // Parse the returned data as URL parameters
                let variables = urlParameters.components(separatedBy: "&")
                let dictionary: [String : String] = variables.reduce(into: [:]) { result, variable in
                    let keyValue = variable.components(separatedBy: "=")
                    if keyValue.count == 2, let decoded = keyValue[1].removingPercentEncoding {
                        result[keyValue[0]] = decoded
                    } else {
                        print("Failed to parse URL parameter: \(keyValue)")
                    }
                }

                // TODO Check dictionary["status"] == "ok"
                // TODO Check player_response["playabilityStatus"]
                guard let playerResponseData = dictionary["player_response"]?.data(using: .utf8),
                    let playerResponse = try? JSONDecoder().decode(PlayerResponse.self, from: playerResponseData) else {
                    observer.send(error: .invalidResponse)
                    return
                }

                observer.send(value: (
                    mixed: playerResponse.streamingData.formats,
                    video: playerResponse.streamingData.adaptiveFormats.filter { $0.audioQuality == nil },
                    audio: playerResponse.streamingData.adaptiveFormats.filter { $0.audioQuality != nil }
                ))
            }.resume()
        }
    }
}
