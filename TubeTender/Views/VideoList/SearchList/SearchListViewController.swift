//
//  SearchListViewController.swift
//  TubeTender
//
//  Created by Noah Peeters on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class SearchListViewController: GenericVideoListViewController {
    let searchController = UISearchController(searchResultsController: nil)
    private var nextPageToken: String?
    private var currentSearchString: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Videos"
        searchController.searchBar.keyboardAppearance = .dark
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func loadVideos(pageToken: String?, action: @escaping ([Video]) -> Void) {
        guard let searchString = currentSearchString, !searchString.isEmpty else {
            notUpdating()
            return
        }

        YoutubeClient.shared.search(forString: searchString, pageToken: pageToken).videos.startWithValues { result in
            guard let result = result.value else { return }

            self.nextPageToken = result.nextPageToken
            action(result.values)
        }
    }

    override func reloadVideos() {
        loadVideos(pageToken: nil) { self.replace(videos: [$0]) }
    }

    override func loadNextVideos() {
        loadVideos(pageToken: nextPageToken) { self.append(videos: $0) }
    }

    override func createEmptyStateView() -> UIView {
        return EmptyStateView(image: #imageLiteral(resourceName: "search"), text: "No videos found")
    }
}

extension SearchListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        currentSearchString = searchBar.text
        reloadVideos()
    }
}
