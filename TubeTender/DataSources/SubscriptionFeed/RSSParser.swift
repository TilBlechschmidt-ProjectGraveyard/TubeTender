//
//  RSSParser.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

struct Entry {
    var videoID: String?
    var channelID: String?
    var title: String?
    var published: String?
    var updated: String?
//    var media: Media
}

struct Media {
    var thumbnail: MediaThumbnail?
//    var community: MediaCommunity?
}

struct MediaThumbnail {
    var url: String?
    var width: String?
    var height: String?
}

//struct MediaCommunity {
//    var starRating: ...
//    var statistics: ...
//}

class YoutubeVideoFeedParser: NSObject, XMLParserDelegate {
    var entries = [Entry]()
    var entry = Entry()
    var foundCharacters = ""

    func startParsing(rssURL: URL) {
        let parser = XMLParser(contentsOf: rssURL)

        parser?.delegate = self;
        parser?.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {

//        if elementName == "tag" {
//            let tempTag = Tag();
//            if let name = attributeDict["name"] {
//                tempTag.name = name;
//            }
//            if let c = attributeDict["count"] {
//                if let count = Int(c) {
//                    tempTag.count = count;
//                }
//            }
//            self.item.tag.append(tempTag);
//        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundCharacters += string;
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "yt:videoId" {
            self.entry.videoID = self.foundCharacters
        }

        if elementName == "yt:channelId" {
            self.entry.channelID = self.foundCharacters
        }

        if elementName == "title" {
            self.entry.title = self.foundCharacters
        }

        if elementName == "published" {
            self.entry.published = self.foundCharacters
        }

        if elementName == "updated" {
            self.entry.updated = self.foundCharacters
        }

        if elementName == "entry" {
            self.entries.append(entry)
            self.entry = Entry()
//            let tempItem = Entry();
//            tempItem.author = self.item.author;
//            tempItem.desc = self.item.desc;
//            tempItem.tag = self.item.tag;
//            self.items.append(tempItem);
//            self.item.tag.removeAll();
        }
        self.foundCharacters = ""
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        for entry in self.entries {
            print("\(entry.title) [ \(entry.videoID) ]");
//            for tags in item.tag {
//                if let count = tags.count {
//                    print("\(tags.name), \(count)")
//                } else {
//                    print("\(tags.name)")
//                }
//            }
        }
    }
}

//class RSSParser: NSObject, XMLParserDelegate {
//    var xmlParser: XMLParser!
//    var currentElement = ""
//    var foundCharacters = ""
//    var currentData = [String:String]()
//    var parsedData = [[String:String]]()
//    var isHeader = true
//
//    func startParsingWithContentsOfUrl(rssURL: URL, with completion: (Bool) -> ()) {
//        let parser = XMLParser(contentsOf: rssURL)
//        parser?.delegate = self
//        if let flag = parser?.parse() {
//            parsedData.append(currentData)
//            completion(flag)
//        }
//    }
//
//    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
//        currentElement = elementName
//
//        if currentElement == "item" || currentElement == "entry" {
//            if !isHeader {
//                parsedData.append(currentData)
//            }
//
//            isHeader = false
//        }
//
//        if !isHeader {
//
//        }
//    }
//}
