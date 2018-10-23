//
//  StreamFormat.swift
//  Pivo
//
//  Created by Til Blechschmidt on 10.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

enum AudioStreamFormat {
    case aac
    case vorbis
    case opus
    case dtse
    case ec3
}

struct AudioStream {
    let bitrate: Int
    let format: AudioStreamFormat
}

enum VideoStreamFormat {
    // Regular files
    case threegp
    case mp4
    case webm

    // Streams
    case hls
    case mpegDash
    case webmDash
}

enum VideoStreamQuality: Int {
    case UHD = 2160
    case QHD = 1440
    case FHD = 1080
    case HD = 720
    case SD = 360
    case LD = 144

    static let array = [UHD, QHD, FHD, HD, SD, LD]
}

struct VideoStream {
    let resolution: (width: Int, height: Int)
    let framerate: Int

    let format: VideoStreamFormat
    
    var quality: VideoStreamQuality? {
        return VideoStreamQuality.array
            .filter { self.resolution.height >= $0.rawValue }
            .min { $0.rawValue > $1.rawValue }
    }

    init(height: Int, format: VideoStreamFormat) {
        self.resolution = (width: height / 9 * 16, height: height)
        self.framerate  = 30
        self.format     = format
    }

    init(height: Int, format: VideoStreamFormat, framerate: Int) {
        self.resolution = (width: height / 9 * 16, height: height)
        self.framerate  = framerate
        self.format     = format
    }
}

enum StreamType {
    case video(VideoStream)
    case audio(AudioStream)
}
