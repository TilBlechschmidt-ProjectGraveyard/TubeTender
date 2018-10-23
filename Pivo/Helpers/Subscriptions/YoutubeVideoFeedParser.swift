//
//  RSSParser.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

struct Entry {
    var videoID: String!
    var title: String!

    var published: Date!
    var updated: Date?

    var viewCount: Int?
    var rating: MediaRating?
    var thumbnail: MediaThumbnail?
    var description: String?

    var channelID: String!
    var authorName: String!
}

struct MediaThumbnail {
    var url: String
    var width: Int
    var height: Int
}

struct MediaRating {
    var count: Int?
    var average: Float?
    var min: Int?
    var max: Int?
}

class YoutubeVideoFeedParser: NSObject, XMLParserDelegate {
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()

    var entries = [Entry]()
    var entry = Entry()
    var foundCharacters = ""

    func startParsing(rssURL: URL) -> [Entry] {
        let parser = XMLParser(contentsOf: rssURL)
        parser?.delegate = self;
        parser?.parse()

        return entries
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {

        if elementName == "media:thumbnail" {
            if let url = attributeDict["url"],
                let height = attributeDict["height"], let intHeight = Int(height),
                let width = attributeDict["width"], let intWidth = Int(width)
            {
                self.entry.thumbnail = MediaThumbnail(url: url, width: intWidth, height: intHeight)
            }
        }

        if elementName == "media:starRating" {
            var rating = MediaRating()

            if let count = attributeDict["count"] {
                rating.count = Int(count)
            }

            if let average = attributeDict["average"] {
                rating.average = Float(average)
            }

            if let min = attributeDict["min"] {
                rating.min = Int(min)
            }

            if let max = attributeDict["max"] {
                rating.max = Int(max)
            }

            entry.rating = rating
        }

        if elementName == "media:statistics", let viewCount = attributeDict["views"] {
            entry.viewCount = Int(viewCount)
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundCharacters += string;
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // Clean up the found characters (remove leading newlines/whitespaces)
        foundCharacters = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)

        if elementName == "yt:videoId" {
            entry.videoID = foundCharacters
        }

        if elementName == "yt:channelId" {
            entry.channelID = foundCharacters
        }

        if elementName == "title" {
            entry.title = foundCharacters
        }

        if elementName == "published" {
            entry.published = dateFormatter.date(from: foundCharacters)
        }

        if elementName == "updated" {
            entry.updated = dateFormatter.date(from: foundCharacters)
        }

        if elementName == "name" {
            entry.authorName = foundCharacters
        }

        if elementName == "media:description" {
            entry.description = foundCharacters
        }

        if elementName == "entry" {
            entries.append(entry)
            entry = Entry()
        }

        foundCharacters = ""
    }
}
