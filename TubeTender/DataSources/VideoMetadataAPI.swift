//
//  VideoMetadata.swift
//  Pivo
//
//  Created by Til Blechschmidt on 27.12.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import YoutubeKit
import ReactiveSwift

enum VideoMetadataAPIError: Error {
    case requestFailed(error: Error)
    case notFound
}

class VideoMetadataAPI {
    static let shared = VideoMetadataAPI()
    private init() {}

    private static let defaultVideoListParts: [Part.VideoList] = [.contentDetails, .statistics, .snippet]

    func fetchMetadata(forVideos videoIDs: [VideoID], withParts parts: [Part.VideoList] = VideoMetadataAPI.defaultVideoListParts) -> SignalProducer<[Video], VideoMetadataAPIError> {
        return SignalProducer(videoIDs).flatMap(.concurrent(limit: 25)) {
            self.fetchMetadata(forVideo: $0)
        }.collect()
    }

    func thumbnailURL(forVideo videoID: VideoID) -> SignalProducer<URL, VideoMetadataAPIError> {
        // TODO If we are offline ask the DownloadManager instead.
        return fetchMetadata(forVideo: videoID, withParts: [.snippet]).attemptMap { videoMetadata in
            if let urlString = videoMetadata.snippet?.thumbnails.high.url, let url = URL(string: urlString) {
                return .success(url)
            } else {
                return .failure(VideoMetadataAPIError.notFound)
            }
        }
    }

    func fetchMetadata(forVideo videoID: VideoID, withParts parts: [Part.VideoList] = VideoMetadataAPI.defaultVideoListParts) -> SignalProducer<Video, VideoMetadataAPIError> {
        return SignalProducer { observer, _ in
            let videoRequest = VideoListRequest(part: parts, filter: .id(videoID))

            ApiSession.shared.send(videoRequest) { result in
                switch result {
                case .success(let response):
                    if response.items.count == 1 {
                        observer.send(value: response.items[0])
                    } else {
                        observer.send(error: .notFound)
                    }
                case .failed(let error):
                    observer.send(error: .requestFailed(error: error))
                }
                observer.sendCompleted()
            }
        }
    }
}
