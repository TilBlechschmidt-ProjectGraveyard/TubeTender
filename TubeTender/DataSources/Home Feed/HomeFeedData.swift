//
//  HomeFeedData.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 01.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

enum HomeFeedDataError: Error {
    case invalidURLEncoding
    case invalidData
}

struct HomeFeedContinuationData: Decodable {
    let sections: [HomeFeedDataSection]
    let continuation: HomeFeedDataContinuation

    init(from decoder: Decoder) throws {
        var unkeyedContainer = try decoder.unkeyedContainer()
        var container = try unkeyedContainer.keyedContainer(at: 1)

        continuation = try container.decode(HomeFeedDataContinuation.self, at: ["response", "continuationContents", "sectionListContinuation", "continuations", 0].reversed())

        sections = try container.decode([HomeFeedDataSection].self, at: ["response", "continuationContents", "sectionListContinuation", "contents"].reversed())
    }
}

struct HomeFeedData: Decodable {
    // Get subfields data from this base path:
    // contents -> twoColumnBrowseResultsRenderer -> tabs[0] -> tabRenderer -> content -> sectionListRenderer

    let sections: [HomeFeedDataSection] // contents[]
    let continuation: HomeFeedDataContinuation // continuations[0]

    init(from decoder: Decoder) throws {
        let prefixPath: [DecodingKey] = ["contents", "twoColumnBrowseResultsRenderer", "tabs", 0, "tabRenderer", "content", "sectionListRenderer"]

        continuation = try decoder.decode(HomeFeedDataContinuation.self, at: prefixPath + ["continuations", 0])

        // Decode sections (sadly a bit more complicated since the first section in the data is invalid :/)
        var container = try decoder.container(keyedBy: KeyWrapper.self)
        container = try container.keyedContainer(at: "contents")
        container = try container.keyedContainer(at: "twoColumnBrowseResultsRenderer")
        var unkeyedContainer = try container.unkeyedContainer(at: "tabs")
        container = try unkeyedContainer.keyedContainer(at: 0)
        container = try container.keyedContainer(at: "tabRenderer")
        container = try container.keyedContainer(at: "content")
        container = try container.keyedContainer(at: "sectionListRenderer")
        unkeyedContainer = try container.unkeyedContainer(at: "contents")

        var sections: [HomeFeedDataSection?] = []
        for index in (unkeyedContainer.currentIndex..<unkeyedContainer.count!) {
            try unkeyedContainer.advance(to: index)
            sections.append(try? unkeyedContainer.decode(HomeFeedDataSection.self))
        }

        self.sections = sections.compactMap { $0 }
    }
}

struct HomeFeedDataContinuation: Decodable {
    let token: String // nextContinuationData -> continuation

    init(from decoder: Decoder) throws {
        let urlEncodedToken = try decoder.decode(String.self, at: ["nextContinuationData", "continuation"])

        // TODO Check if this is required
        guard let token = urlEncodedToken.removingPercentEncoding else {
            throw HomeFeedDataError.invalidURLEncoding
        }

        self.token = token
    }
}

struct HomeFeedDataSection: Decodable {
    // Get subfields data from this base path:
    // itemSectionRenderer -> contents[0] -> shelfRenderer

    let title: String // title -> simpleText
    let subtitle: String? // titleAnnotation -> simpleText

    let thumbnailURL: String? // thumbnail -> thumbnails[0] -> url

    let items: [HomeFeedDataSectionItem] // content -> gridRenderer -> items[] || content -> horizontalListRenderer -> items[]

    // For later use:
    // playEndpoint -> commandMetadata -> webCommandMetadata -> url --- Link to more details/subcategories per topic
    // menu -> topLevelButtons --- Contains stuff like e.g. 'dismiss' buttons if not interested in topic

    init(from decoder: Decoder) throws {
        let prefixPath: [DecodingKey] = ["itemSectionRenderer", "contents", 0, "shelfRenderer"]

        title = try decoder.decode(String.self, at: prefixPath + ["title", "simpleText"])
        subtitle = try? decoder.decode(String.self, at: prefixPath + ["titleAnnotation", "simpleText"])

        thumbnailURL = try? decoder.decode(String.self, at: prefixPath + ["thumbnail", 0, "url"])

        let gridItems = try? decoder.decode([HomeFeedDataSectionItem].self, at: prefixPath + ["content", "gridRenderer", "items"])
        let listItems = try? decoder.decode([HomeFeedDataSectionItem].self, at: prefixPath + ["content", "horizontalListRenderer", "items"])

        guard let items = gridItems ?? listItems else {
            throw HomeFeedDataError.invalidData
        }

        self.items = items
    }
}

struct HomeFeedDataSectionItem: Decodable {
    // Get subfields data from this base path:
    // gridVideoRenderer
    let videoID: Video.ID // videoId

    // To reduce quota usage the following fields could be used:
    // thumbnail -> thumbnails[0] -> url
    // shortViewCountText -> simpleText || viewCountText -> simpleText
    // title -> simpleText
    // publishedTimeText -> simpleText
    // shortBylineText -> runs[0] -> text --- Channel name

    init(from decoder: Decoder) throws {
        let prefixPath: [DecodingKey] = ["gridVideoRenderer"]

        videoID = try decoder.decode(String.self, at: prefixPath + ["videoId"])
    }
}

struct KeyWrapper: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        return nil
    }
}

private struct DummyCodable: Codable {}

enum DecodingKey: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    typealias StringLiteralType = String
    typealias IntegerLiteralType = Int

    case string(_ value: StringLiteralType)
    case index(_ value: IntegerLiteralType)

    init(integerLiteral value: IntegerLiteralType) {
        self = .index(value)
    }

    init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

enum CustomDecodingError: Error {
    case invalidParameters
    case indexOutOfBounds
}

extension Decoder {
    func decode<T: Decodable>(_ type: T.Type, at path: [DecodingKey]) throws -> T {
        guard !path.isEmpty else {
            throw CustomDecodingError.invalidParameters
        }

        let newPath = Array(path.reversed())

        if path.count == 1 {
            switch path.first! {
            case .index:
                var returnContainer = try unkeyedContainer()
                return try returnContainer.decode(type, at: path)
            case .string(let value):
                return try container(keyedBy: KeyWrapper.self).decode(type, forKey: KeyWrapper(stringValue: value))
            }
        } else {
            switch newPath.last! {
            case .index:
                var returnContainer = try unkeyedContainer()
                return try returnContainer.decode(type, at: newPath)
            case .string:
                var returnContainer = try container(keyedBy: KeyWrapper.self)
                return try returnContainer.decode(type, at: newPath)
            }
        }
    }
}

extension KeyedDecodingContainer where K == KeyWrapper {
    mutating func decode<T: Decodable>(_ type: T.Type, at path: [DecodingKey]) throws -> T {
        var newPath = path

        guard let currentPathComponentKey = newPath.popLast() else {
            throw CustomDecodingError.invalidParameters
        }

        let currentPathComponent: String
        switch currentPathComponentKey {
        case .string(let value):
            currentPathComponent = value
        default:
            throw CustomDecodingError.invalidParameters
        }

        if let nextPathComponent = newPath.last {
            switch nextPathComponent {
            case .string:
                var returnContainer = try keyedContainer(at: currentPathComponent)
                return try returnContainer.decode(type, at: newPath)
            case .index:
                var returnContainer = try unkeyedContainer(at: currentPathComponent)
                return try returnContainer.decode(type, at: newPath)
            }
        } else {
            return try decode(type, forKey: KeyWrapper(stringValue: currentPathComponent))
        }
    }

    mutating func keyedContainer(at path: String) throws -> KeyedDecodingContainer<KeyWrapper> {
        return try nestedContainer(keyedBy: KeyWrapper.self, forKey: KeyWrapper(stringValue: path))
    }

    mutating func unkeyedContainer(at path: String) throws -> UnkeyedDecodingContainer {
        return try nestedUnkeyedContainer(forKey: KeyWrapper(stringValue: path))
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode<T: Decodable>(_ type: T.Type, at path: [DecodingKey]) throws -> T {
        var newPath = path

        guard let currentPathComponentKey = newPath.popLast() else {
            throw CustomDecodingError.invalidParameters
        }

        let currentPathComponent: Int
        switch currentPathComponentKey {
        case .index(let value):
            currentPathComponent = value
        default:
            throw CustomDecodingError.invalidParameters
        }

        if let nextPathComponent = newPath.last {
            switch nextPathComponent {
            case .string:
                var returnContainer = try keyedContainer(at: currentPathComponent)
                return try returnContainer.decode(type, at: newPath)
            case .index:
                var returnContainer = try unkeyedContainer(at: currentPathComponent)
                return try returnContainer.decode(type, at: newPath)
            }
        } else {
            try advance(to: currentPathComponent)
            return try self.decode(type)
        }
    }

    mutating func advance(to index: Int) throws {
        guard index < count ?? 0, currentIndex <= index else {
            throw CustomDecodingError.indexOutOfBounds
        }

        while currentIndex < index {
            // TODO Check if this works on non-homogenous arrays with scalars and sub-containers
            _ = try self.decode(DummyCodable.self)
        }
    }

    mutating func keyedContainer(at index: Int) throws -> KeyedDecodingContainer<KeyWrapper> {
        try advance(to: index)
        return try nestedContainer(keyedBy: KeyWrapper.self)
    }

    mutating func unkeyedContainer(at index: Int) throws -> UnkeyedDecodingContainer {
        try advance(to: index)
        return try nestedUnkeyedContainer()
    }
}
