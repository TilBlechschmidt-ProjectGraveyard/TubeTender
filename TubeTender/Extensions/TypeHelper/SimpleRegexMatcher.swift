//
//  SimpleRegexMatcher.swift
//  Test
//
//  Created by Til Blechschmidt on 10.10.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

struct SimpleRegexMatch {
    let groups: [Substring?]
}

struct SimpleRegexMatcher {

    static func matches(forPattern pattern: String, in string: String) -> [SimpleRegexMatch]? {
        let range = NSRange(location: 0, length: string.count)

        guard let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options()) else {
            return nil
        }

        return regex.matches(in: string, options: NSRegularExpression.MatchingOptions(), range: range).map { match in
            SimpleRegexMatch(groups: (0..<match.numberOfRanges).map { rangeNumber in
                Range(match.range(at: rangeNumber), in: string).flatMap { string[$0] }
            })
        }
    }

    static func firstMatch(forPattern pattern: String, in string: String) -> SimpleRegexMatch? {
        let range = NSRange(location: 0, length: string.count)

        guard let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options()) else {
            return nil
        }

        guard let match = regex.firstMatch(in: string, options: NSRegularExpression.MatchingOptions(), range: range) else {
            return nil
        }

        return SimpleRegexMatch(groups: (0..<match.numberOfRanges).map { rangeNumber in
            Range(match.range(at: rangeNumber), in: string).flatMap { string[$0] }
        })
    }
}
