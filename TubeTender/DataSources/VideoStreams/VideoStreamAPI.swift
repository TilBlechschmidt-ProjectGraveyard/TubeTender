//
//  VideoStreamAPI.swift
//  Pivo
//
//  Created by Til Blechschmidt on 04.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation
import ReactiveSwift

enum VideoStreamAPIError: Error {
    case invalidRequestURL
    case invalidResponse
}

typealias StreamCollection = (mixed: [StreamMetadata], video: [StreamMetadata], audio: [StreamMetadata])

final class VideoStreamAPI {
    fileprivate static let videoInfoPath = "https://www.youtube.com/get_video_info?video_id=%@&asv=3&el=detailpage&ps=default&hl=en_US"

    static let shared = VideoStreamAPI()

    private init() {}

    func streamManager(forVideoID videoID: String) -> SignalProducer<VideoStreamManager, VideoStreamAPIError> {
        return self.streams(forVideoID: videoID).map { VideoStreamManager(withStreams: $0) }
    }

    func streams(forVideoID videoID: String) -> SignalProducer<StreamCollection, VideoStreamAPIError> {
        return SignalProducer { observer, _ in
            // Build the request URL
            let path = String(format: VideoStreamAPI.videoInfoPath, videoID)
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
                guard let apiResponseData = dictionary["player_response"]?.data(using: .utf8),
                    let apiResponse = try? JSONDecoder().decode(VideoStreamAPIResponse.self, from: apiResponseData) else {
                    observer.send(error: .invalidResponse)
                    return
                }

                observer.send(value: (
                    mixed: apiResponse.streamingData.formats,
                    video: apiResponse.streamingData.adaptiveFormats.filter { $0.audioQuality == nil },
                    audio: apiResponse.streamingData.adaptiveFormats.filter { $0.audioQuality != nil }
                ))
            }.resume()
        }
    }
}
