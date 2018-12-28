//
//  StreamMetadata.swift
//  Pivo
//
//  Created by Til Blechschmidt on 04.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

enum StreamQuality: String, Codable, ArrayComparable {
    case highres // 4320p
    case hd2160 // 2160p
    case hd1440 // 1440p
    case hd1080 // 1080p
    case hd720 // 720p
    case large // 480p
    case medium // 360p
    case small // 240p
    case tiny // 144p || audio

    static let ascendingOrder: [StreamQuality] = [.tiny, .small, .medium, .large, .hd720, .hd1080, .hd1440, .hd2160, .highres]
}

enum StreamAudioQuality: String, Codable, ArrayComparable {
    case high = "AUDIO_QUALITY_HIGH"
    case medium = "AUDIO_QUALITY_MEDIUM"
    case low = "AUDIO_QUALITY_LOW"

    static let ascendingOrder: [StreamAudioQuality] = [.low, .medium, .high]
}

class StreamMetadata: Codable {
    // Generic
    let itag: Int
    let lastModified: String
    let mimeType: String
    let url: String

    let contentLength: String?
    let approxDurationMs: String?

    let quality: StreamQuality
    let bitrate: Int
    let averageBitrate: Int?
    let projectionType: String

    // Video
    let width: Int?
    let height: Int?
    let fps: Int?
    let qualityLabel: String?

    // Audio
    let audioQuality: StreamAudioQuality?
    let audioSampleRate: String?

    // let colorInfo -> Can tell us whether or not it is HDR
    // let initRange
    // let indexRange
    // let highReplication

    var highFPS: Bool {
        return fps ?? 30 > 30
    }

    var hdr: Bool {
        return qualityLabel?.contains("HDR") ?? false
    }
}

struct StreamingData: Codable {
    let expiresInSeconds: String
    let formats: [StreamMetadata]
    let adaptiveFormats: [StreamMetadata]
    let probeUrl: String?
}

struct VideoStreamAPIResponse: Codable {
    let streamingData: StreamingData
}
