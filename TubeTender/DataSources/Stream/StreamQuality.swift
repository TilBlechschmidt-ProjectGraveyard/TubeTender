//
//  StreamQuality.swift
//  TubeTender
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
    case tiny // 144p

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

extension StreamQuality {
    static var `default`: StreamQuality {
        return (Settings.get(setting: .DefaultQuality) as? String).flatMap { StreamQuality(rawValue: $0) } ?? .hd720
    }

    static var mobile: StreamQuality {
        return (Settings.get(setting: .MobileQuality) as? String).flatMap { StreamQuality(rawValue: $0) } ?? .medium
    }
}
