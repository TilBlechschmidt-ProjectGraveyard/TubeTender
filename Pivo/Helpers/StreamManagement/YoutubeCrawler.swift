//
//  YoutubeCrawler.swift
//  Pivo
//
//  Created by Til Blechschmidt on 10.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

class YoutubeCrawler {
    static let videoInfoPath = "https://www.youtube.com/get_video_info?video_id=%@&asv=3&el=detailpage&ps=default&hl=en_US"

    static let itags: [String : StreamType] = [
        // Regular video formats
        "17": StreamType.video(VideoStream(height: 133, format: .threegp)),
        "18": StreamType.video(VideoStream(height: 133, format: .mp4)),
        "22": StreamType.video(VideoStream(height: 720, format: .mp4)),
        "36": StreamType.video(VideoStream(height: 144, format: .threegp)),
        "43": StreamType.video(VideoStream(height: 360, format: .webm)),

        // 3D videos

        // HLS

        // DASH mp4 video (h264)
        "160": StreamType.video(VideoStream(height: 144, format: .mpegDash)),
        "133": StreamType.video(VideoStream(height: 240, format: .mpegDash)),
        "134": StreamType.video(VideoStream(height: 360, format: .mpegDash)),
        "135": StreamType.video(VideoStream(height: 480, format: .mpegDash)),
        "136": StreamType.video(VideoStream(height: 720, format: .mpegDash)),
        "137": StreamType.video(VideoStream(height: 1080, format: .mpegDash)),
        "264": StreamType.video(VideoStream(height: 1440, format: .mpegDash)),
        "266": StreamType.video(VideoStream(height: 2160, format: .mpegDash)),

        "298": StreamType.video(VideoStream(height: 720, format: .mpegDash, framerate: 60)),
        "299": StreamType.video(VideoStream(height: 1080, format: .mpegDash, framerate: 60)),

        // DASH mp4 audio
        "140": StreamType.audio(AudioStream(bitrate: 128, format: .aac)),

        // DASH webm video
        "278": StreamType.video(VideoStream(height: 144, format: .webmDash)),
        "242": StreamType.video(VideoStream(height: 240, format: .webmDash)),
        "243": StreamType.video(VideoStream(height: 360, format: .webmDash)),
        "244": StreamType.video(VideoStream(height: 480, format: .webmDash)),
        "245": StreamType.video(VideoStream(height: 480, format: .webmDash)),
        "246": StreamType.video(VideoStream(height: 480, format: .webmDash)),
        "247": StreamType.video(VideoStream(height: 720, format: .webmDash)),
        "248": StreamType.video(VideoStream(height: 1080, format: .webmDash)),
        "271": StreamType.video(VideoStream(height: 1440, format: .webmDash)),
        "272": StreamType.video(VideoStream(height: 2160, format: .webmDash)),

        // DASH webm audio
        "171": StreamType.audio(AudioStream(bitrate: 128, format: .vorbis)),
        "172": StreamType.audio(AudioStream(bitrate: 256, format: .vorbis)),
        "249": StreamType.audio(AudioStream(bitrate: 50, format: .opus)),
        "250": StreamType.audio(AudioStream(bitrate: 70, format: .opus)),
        "251": StreamType.audio(AudioStream(bitrate: 160, format: .opus)),
    ]

    class func streamManager(forVideoID youtubeID: String, completionHandler handler: @escaping (StreamManager) -> Void) {
        let path = String(format: videoInfoPath, youtubeID)
        let url = URL(string: path)
        var req = URLRequest(url: url!)
        req.addValue("en", forHTTPHeaderField: "Accept-Language")

        let session = URLSession(configuration: URLSessionConfiguration.default)

        session.dataTask(with: req) { data, response, error in
            guard let data = data, data.count > 0,
                let html = String(data: data, encoding: .utf8)?.removingPercentEncoding
                else {
                    // TODO Notify the handler
                    print("Received invalid data")
                    return
            }

            print(html)

            guard let matches = SimpleRegexMatcher.matches(forPattern: "&url=(.*?videoplayback.*?)&", in: html) else {
                // TODO Notify the handler
                print("Failed to execute regex")
                return
            }

            let streams = matches.compactMap { (match: SimpleRegexMatch) -> (type: StreamType, url: String)? in
                guard let url = match.groups[1].flatMap({ String($0).removingPercentEncoding }) else {
                    return nil
                }

                guard let itagMatch = SimpleRegexMatcher.firstMatch(forPattern: "&itag=(\\d+)&?", in: url),
                    let itagString = itagMatch.groups[1],
                    let streamType = itags[String(itagString)]
                else {
                        return nil
                }

                return (type: streamType, url: url)
            }

            handler(StreamManager(streams: streams))
        }.resume()
    }
}
