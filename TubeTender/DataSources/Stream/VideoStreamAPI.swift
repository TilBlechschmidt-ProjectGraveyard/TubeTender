//
//  VideoStreamAPI.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 04.11.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import ReactiveSwift

enum VideoStreamAPIError: Error {
    case invalidRequestURL
    case invalidResponse
}

final class VideoStreamAPI {
    fileprivate static let videoInfoPath = "https://www.youtube.com/get_video_info?video_id=%@&asv=3&el=detailpage&ps=default&hl=en_US"

    static let shared = VideoStreamAPI()

    private init() {}

    func streams(forVideoID videoID: String) -> SignalProducer<[StreamDescriptor], Error> {
        return SignalProducer { observer, _ in
            // Build the request URL
            let path = String(format: VideoStreamAPI.videoInfoPath, videoID)
            guard let url = URL(string: path) else {
                observer.send(error: VideoStreamAPIError.invalidRequestURL)
                return
            }

            // Build the request
            var req = URLRequest(url: url)
            req.addValue("en", forHTTPHeaderField: "Accept-Language")

            // Send the request
            let session = URLSession(configuration: URLSessionConfiguration.default)
            session.dataTask(with: req) { data, _, error in
                // Convert the response to a string
                guard let data = data, !data.isEmpty, let urlParameters = String(data: data, encoding: .utf8) else {
                    observer.send(error: VideoStreamAPIError.invalidResponse)
                    return
                }

                // Parse the returned data as URL parameters
                let dictionary = dictionaryFromURL(parameterStrings: urlParameters.components(separatedBy: "&"))

                // Extract the list of streams and convert them to dictionaries
                guard let adaptiveFormats = dictionary["adaptive_fmts"] else {
                    observer.send(error: VideoStreamAPIError.invalidResponse)
                    return
                }

                let streams = adaptiveFormats.components(separatedBy: ",")
                let formattedStreamDictionaries = streams.map { stream in
                    return dictionaryFromURL(parameterStrings: stream.split(separator: "&").map { String($0) })
                }

                // Parse the dictionaries into structs
                let streamDescriptors = formattedStreamDictionaries.map { StreamDescriptor(fromDict: $0) }

                observer.send(value: streamDescriptors)
                observer.sendCompleted()
            }.resume()
        }
    }
}

private func dictionaryFromURL(parameterStrings: [String]) -> [String: String] {
    return parameterStrings.reduce(into: [:]) { result, variable in
        let keyValue = variable.components(separatedBy: "=")
        if keyValue.count == 2, let decoded = keyValue[1].removingPercentEncoding {
            result[keyValue[0]] = decoded
        } else {
            print("Failed to parse URL parameter: \(keyValue)")
        }
    }
}
