//
//  HLSBuilder.swift
//  HLSServer
//
//  Created by Til Blechschmidt on 20.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import Result

typealias VideoID = String
typealias ITag = String

enum HLSBuilderError: Error {
    case itagDescriptorNotFound
    case unableToReadSegmentData
}

class HLSBuilder {
    let videoStreamAPI: VideoStreamAPI
    var cache: [VideoID: [ITag: StreamDescriptor]]

    init(videoStreamAPI: VideoStreamAPI = VideoStreamAPI.shared) {
        self.videoStreamAPI = videoStreamAPI
        self.cache = [:]
    }

    private func addToCache(_ streamDescriptor: StreamDescriptor, videoID: VideoID) {
        if cache.index(forKey: videoID) == nil {
            cache[videoID] = [:]
        }

        cache[videoID]?[streamDescriptor.itag] = streamDescriptor
    }

    func streamsDescriptors(forVideoID videoID: VideoID) -> SignalProducer<[StreamDescriptor], AnyError> {
        // TODO Take cache age into account (after a certain time the cache invalidates because the URLs expire)
        if let descriptors = cache[videoID] {
            return SignalProducer(value: Array(descriptors.values))
        } else {
            return videoStreamAPI.streams(forVideoID: videoID)
        }
    }

    func masterPlaylist(forVideoID videoID: VideoID) -> SignalProducer<String, AnyError> {
        let m3u8Header = """
        #EXTM3U
        #EXT-X-VERSION:4


        """

        return streamsDescriptors(forVideoID: videoID)
            .flatten()
            .filter { $0.mimeType.contains("mp4") } // Since HLS only supports fMP4 streams we can dump all the webm streams
            // TODO We probably need to filter the codecs to not include vp9
            .on { streamDescriptor in
                self.addToCache(streamDescriptor, videoID: videoID)
            }
            .map { streamDescriptor in
                let streamManifestURL = "\(videoID)/\(streamDescriptor.itag ?? "invalidITag").m3u8"
                if streamDescriptor.audioChannels != nil {
                    return """
                    #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="en",NAME="English",DEFAULT=YES,AUTOSELECT=YES,URI="\(streamManifestURL)"
                    """
                } else {
                    return """
                    #EXT-X-STREAM-INF:BANDWIDTH=\(streamDescriptor.bitrate ?? 0),CODECS="\(streamDescriptor.codecs ?? "")",RESOLUTION=\(streamDescriptor.width ?? 0)x\(streamDescriptor.height ?? 0),AUDIO="aac"
                    \(streamManifestURL)
                    """
                }
            }
            .collect()
            .map { m3u8Header + $0.joined(separator: "\n") }
    }

    func playlist(forVideoID videoID: VideoID, itag: ITag) -> SignalProducer<String, AnyError> {
        return streamsDescriptors(forVideoID: videoID)
            .flatten()
            .filter { $0.itag == itag }
            .collect()
            .attemptMap { descriptors in
                guard descriptors.count == 1, let descriptor = descriptors.first else {
                    throw AnyError(HLSBuilderError.itagDescriptorNotFound)
                }

                return descriptor
            }
            .flatMap(.merge) { (descriptor: StreamDescriptor) -> SignalProducer<String, AnyError> in
                let path = descriptor.url!
                let url = URL(string: descriptor.url)!
                let index = descriptor.index!

                return SignalProducer { observer, _ in
                    var request = URLRequest(url: url)
                    request.setValue("bytes=\(index.lowerBound)-\(index.upperBound)", forHTTPHeaderField: "Range")

                    let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                        guard let data = data else {
                            observer.send(error: AnyError(HLSBuilderError.unableToReadSegmentData))
                            return
                        }

                        let info = SegmentInformation(fromData: data, inRange: 0..<index.count+1)

                        observer.send(value: info.generateM3U8(withFilePath: path))
                        observer.sendCompleted()
                    }

                    task.resume()
                }
            }
    }
}
