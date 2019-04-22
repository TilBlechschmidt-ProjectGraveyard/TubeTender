//
//  StreamMetadata.swift
//  Pivo
//
//  Created by Til Blechschmidt on 04.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

enum StreamQuality: String, Codable, ArrayComparable, CustomStringConvertible {
    case hd1080 // 1080p
    case hd720 // 720p
    case large // 480p
    case medium // 360p
    case small // 240p
    case tiny // 144p || audio

    var description: String {
        return "\(Int(resolution.height))p"
    }

    var resolution: CGSize {
        let height: CGFloat
        
        switch self {
        case .tiny:
            height = 144
        case .small:
            height = 240
        case .medium:
            height = 360
        case .large:
            height = 480
        case .hd720:
            height = 720
        case .hd1080:
            height = 1080
        }

        return CGSize(width: height / 9 * 16, height: height)
    }

    static let ascendingOrder: [StreamQuality] = [.tiny, .small, .medium, .large, .hd720, .hd1080]

    static func from(videoSize: CGSize) -> StreamQuality? {
        let height = videoSize.height

        switch height {
        case 144:
            return .tiny
        case 240:
            return .small
        case 360:
            return .medium
        case 480:
            return .large
        case 720:
            return .hd720
        case 1080:
            return .hd1080
        default:
            return nil
        }
    }
}

//enum StreamAudioQuality: String, Codable, ArrayComparable {
//    case high = "AUDIO_QUALITY_HIGH"
//    case medium = "AUDIO_QUALITY_MEDIUM"
//    case low = "AUDIO_QUALITY_LOW"
//
//    static let ascendingOrder: [StreamAudioQuality] = [.low, .medium, .high]
//}
//
//class StreamMetadata: Codable {
//    // Generic
//    let itag: Int
//    let lastModified: String
//    let mimeType: String
//    let url: String
//
//    let contentLength: String?
//    let approxDurationMs: String?
//
//    let quality: StreamQuality
//    let bitrate: Int
//    let averageBitrate: Int?
//    let projectionType: String
//
//    // Video
//    let width: Int?
//    let height: Int?
//    let fps: Int?
//    let qualityLabel: String?
//
//    // Audio
//    let audioQuality: StreamAudioQuality?
//    let audioSampleRate: String?
//
//    // let colorInfo -> Can tell us whether or not it is HDR
//    // let initRange
//    // let indexRange
//    // let highReplication
//
//    var highFPS: Bool {
//        return fps ?? 30 > 30
//    }
//
//    var hdr: Bool {
//        return qualityLabel?.contains("HDR") ?? false
//    }
//}
//
//struct StreamingData: Codable {
//    let expiresInSeconds: String
//    let formats: [StreamMetadata]
//    let adaptiveFormats: [StreamMetadata]
//    let probeUrl: String?
//}
//
//struct VideoStreamAPIResponse: Codable {
//    let streamingData: StreamingData
//}

extension StreamQuality {
    static var `default`: StreamQuality {
        return (Settings.get(setting: .DefaultQuality) as? String).flatMap { StreamQuality(rawValue: $0) } ?? .hd720
    }

    static var mobile: StreamQuality {
        return (Settings.get(setting: .MobileQuality) as? String).flatMap { StreamQuality(rawValue: $0) } ?? .medium
    }
}
