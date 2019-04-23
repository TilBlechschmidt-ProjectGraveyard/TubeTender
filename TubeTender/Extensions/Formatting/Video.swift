//
//  Snippet.VideoList.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 28.12.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import YoutubeKit

extension ContentDetails.VideoList {
    var durationInterval: TimeInterval? {
        guard let match = SimpleRegexMatcher.firstMatch(forPattern: "P(?:([0-9]+)Y)?(?:([0-9]+)M)?(?:([0-9]+)D)?T(?:([0-9]+)H)?(?:([0-9]+)M)?([0-9]+(.[0-9]+)?S)?", in: self.duration) else {
            return nil
        }

        let hours = Int(match.groups[4] ?? "0") ?? 0
        let minutes = Int(match.groups[5] ?? "0") ?? 0
        let seconds = Int(match.groups[6]?.replacingOccurrences(of: "S", with: "") ?? "0") ?? 0

        return Double((hours * 60 * 60) + (minutes * 60) + seconds)
    }

    var durationPretty: String {
        guard let match = SimpleRegexMatcher.firstMatch(forPattern: "P(?:([0-9]+)Y)?(?:([0-9]+)M)?(?:([0-9]+)D)?T(?:([0-9]+)H)?(?:([0-9]+)M)?([0-9]+(.[0-9]+)?S)?", in: self.duration) else {
            return "--:--"
        }

        let hours = Int(match.groups[4] ?? "0") ?? 0
        let minutes = Int(match.groups[5] ?? "0")
        let seconds = Int(match.groups[6]?.replacingOccurrences(of: "S", with: "") ?? "0")

        let result = String(format: "%02d:%02d", minutes ?? 0, seconds ?? 0)

        return hours > 0 ? String(format: "%02d:%@", hours, result) : result
    }
}
