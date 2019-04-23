//
//  YoutubeURLParser.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 08.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

struct YoutubeURL {
    private static let RegularExpression = "^((?:https?:)?\\/\\/)?((?:www|m)\\.)?((?:youtube\\.com|youtu.be))(\\/(?:[\\w\\-]+\\?v=|embed\\/|v\\/)?)([\\w\\-]+)(\\S+)?$"

    let urlProtocol: String?
    let subdomain: String?
    let domain: String
    let path: String
    let videoID: String
    let queryParameters: String?

    init?(urlString: String) {
        guard let match = SimpleRegexMatcher.firstMatch(forPattern: YoutubeURL.RegularExpression, in: urlString),
                let domain = match.groups[3],
                let path = match.groups[4],
                let videoID = match.groups[5]
            else {
                return nil
        }

        self.urlProtocol = match.groups[1].flatMap(String.init)
        self.subdomain = match.groups[2].flatMap(String.init)
        self.domain = String(domain)
        self.path = String(path)
        self.videoID = String(videoID)
        self.queryParameters = match.groups[6].flatMap(String.init)
    }
}
