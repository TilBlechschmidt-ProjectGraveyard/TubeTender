//
//  SearchAPI.swift
//  TubeTender
//
//  Created by Noah Peeters on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import struct YoutubeKit.SearchResult
import struct YoutubeKit.SearchList
import struct YoutubeKit.SearchListRequest
import Result
import ReactiveSwift
import ReactiveCocoa

struct PagedResult<Value> {
    let nextPageToken: String?
    let values: [Value]
}

public class SearchResult: YoutubeClientObject<YoutubeKit.SearchListRequest, YoutubeKit.SearchList> {
    public let searchString: String
    public let pageToken: String?

    fileprivate init(searchString: String, pageToken: String?, client: YoutubeClient) {
        let channelRequest = SearchListRequest(part: [.snippet], maxResults: 50, pageToken: pageToken, searchQuery: searchString)

        self.searchString = searchString
        self.pageToken = pageToken
        super.init(client: client, request: channelRequest) { $0 }
    }

    var items: APISignalProducer<PagedResult<YoutubeKit.SearchResult>> {
        return makeProperty { PagedResult(nextPageToken: $0.nextPageToken, values: $0.items) }
    }

    var videos: APISignalProducer<PagedResult<Video>> {
        return makeProperty {
            PagedResult(
                nextPageToken: $0.nextPageToken,
                values: $0.items.compactMap({ $0.id.videoID }).map { self.client.video(withID: $0) }
            )
        }
    }

    var channels: APISignalProducer<PagedResult<Channel>> {
        return makeProperty {
            PagedResult(
                nextPageToken: $0.nextPageToken,
                values: $0.items.compactMap({ $0.id.channelID }).map { self.client.channel(withID: $0) }
            )
        }
    }
}

extension YoutubeClient {
    func search(forString searchString: String, pageToken: String? = nil) -> SearchResult {
        return SearchResult(searchString: searchString, pageToken: pageToken, client: self)
    }
}
