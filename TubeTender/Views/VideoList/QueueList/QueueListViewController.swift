//
//  QueueListViewController.swift
//  TubeTender
//
//  Created by Noah Peeters on 09.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

class QueueListViewController: GenericVideoListViewController {
    private let player = VideoPlayer.shared

    func indexPath(from index: Int, withCurrentIndex currentIndex: Int) -> IndexPath {
        if index < currentIndex {
            return IndexPath(row: index, section: 0)
        } else if index == currentIndex {
            return IndexPath(row: 0, section: 1)
        } else { // index > currentIndex
            return IndexPath(row: index - currentIndex - 1, section: 2)
        }
    }

    func indexPath(from index: Int) -> IndexPath {
        guard let currentIndex = player.currentIndex.value else {
            return IndexPath(row: index, section: 0)
        }

        return indexPath(from: index, withCurrentIndex: currentIndex)
    }

    func index(from indexPath: IndexPath) -> Int {
        guard let currentIndex = player.currentIndex.value else {
            return indexPath.row
        }

        if indexPath.section == 0 {
            return indexPath.row
        } else if indexPath.section == 1 {
            return indexPath.row + videos(fromSection: 0, currentIndex: currentIndex).count
        } else { // indexPath.section == 3
            return indexPath.row + videos(fromSection: 0, currentIndex: currentIndex).count + 1
        }
    }

    override func viewDidLoad() {
        super.dataSource = self
        super.viewDidLoad()

        player.changeSetSignal.observeValues { change in
            switch change {
            case .inserted(let insertionIndex):
                self.tableView.insertRows(at: [self.indexPath(from: insertionIndex)], with: .automatic)
            default:
                break
            }
        }

        player.currentIndex.producer.combinePrevious().startWithValues { [unowned self] previousIndex, newIndex in
            if let previousIndex = previousIndex, let newIndex = newIndex {
                let oldPlayingItemIndexPath = self.indexPath(from: previousIndex, withCurrentIndex: newIndex)

                self.tableView.beginUpdates()
                for itemIndex in 0..<self.player.videos.value.count {
                    let previousItemIndexPath = self.indexPath(from: itemIndex, withCurrentIndex: previousIndex)
                    let newItemIndexPath = self.indexPath(from: itemIndex, withCurrentIndex: newIndex)

                    if previousItemIndexPath != newItemIndexPath {
                        self.tableView.moveRow(at: previousItemIndexPath, to: newItemIndexPath)
                    }
                }
                self.tableView.endUpdates()

                self.tableView.reloadRows(at: [oldPlayingItemIndexPath], with: .automatic)
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
            }
        }
    }

    override func hideThumbnail(at indexPath: IndexPath) -> Bool {
        return indexPath.section != 1
    }

    override func headerTitle(forSection section: Int) -> String? {
        return ["History", "Playing", "Up Next"][section]
    }

    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
        return false
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        player.setIndex(to: index(from: indexPath))
        return nil
    }
}

extension QueueListViewController: GenericVideoListViewControllerDataSource {
    private func videos(fromSection section: Int, currentIndex: Int) -> ArraySlice<Video> {
        if section == 0 {
            return player.videos.value[..<currentIndex]
        } else if section == 1 {
            return [player.videos.value[currentIndex]]
        } else { // section == 3
            return player.videos.value[(currentIndex+1)...]
        }
    }

    func numberOfSections() -> Int {
        return 3
    }

    func numberOfRows(in section: Int) -> Int {
        guard let currentIndex = player.currentIndex.value else {
            return section == 0 ? player.videos.value.count : 0
        }

        return videos(fromSection: section, currentIndex: currentIndex).count
    }

    func getVideo(_ section: Int, row: Int) -> Video {
        guard let currentIndex = player.currentIndex.value else {
            fatalError("Attempted to get video from empty section")
        }

        let sectionContent = videos(fromSection: section, currentIndex: currentIndex)
        return sectionContent[sectionContent.startIndex.advanced(by: row)]
    }
}
