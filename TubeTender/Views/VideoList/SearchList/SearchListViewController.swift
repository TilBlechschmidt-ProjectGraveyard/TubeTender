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
        definesPresentationContext = true
    }

    private func loadVideos(pageToken: String?, action: @escaping ([Video]) -> ()) {
        guard let searchString = currentSearchString, searchString != "" else { return }

        YoutubeClient.shared.search(forString: searchString, pageToken: pageToken).videos.startWithValues { result in
            guard let result = result.value else { return }

            self.nextPageToken = result.nextPageToken
            action(result.values)
        }
    }

    override func reloadVideos() {
        loadVideos(pageToken: nil, action: self.replace)
    }

    override func loadNextVideos() {
        loadVideos(pageToken: nextPageToken, action: self.append)
    }
}

extension SearchListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        currentSearchString = searchBar.text
        reloadVideos()
    }
}
