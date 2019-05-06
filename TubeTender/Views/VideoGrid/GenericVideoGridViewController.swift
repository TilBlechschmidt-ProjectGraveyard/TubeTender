//
//  VideoGridViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 02.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit

struct GenericVideoGridViewSection {
    let title: String
    let subtitle: String?
    let icon: URL?
    let items: [Video]
}

class GenericVideoGridViewController: UICollectionViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // TODO Only do on iPhone
        return .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    let sectionBased: Bool

    let topSafeAreaOverlayView = UIView()

    let videoPlayer: VideoPlayer
    let layout = UICollectionViewFlowLayout()
    var sections: [GenericVideoGridViewSection] = []

    var fetching = false {
        didSet {
            if !fetching {
                DispatchQueue.main.async {
                    self.collectionView.refreshControl?.endRefreshing()
                }
            }
        }
    }

    func refreshItemSize() {
        let isSmallDevice = UIDevice.current.userInterfaceIdiom == .phone
        let frameWidth = collectionView.contentSize.width
        let defaultItemWidth = CGFloat(300.0)
        let itemPadding = isSmallDevice ? 0 : 2 * Constants.uiPadding
        let itemWidth = isSmallDevice ? frameWidth - itemPadding : defaultItemWidth
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 0.5625 + Constants.channelIconSize + 2 * Constants.uiPadding)
    }

    init(videoPlayer: VideoPlayer, fetchInitialData: Bool = true, sectionBased: Bool = true) {
        self.videoPlayer = videoPlayer
        self.sectionBased = sectionBased
        super.init(collectionViewLayout: layout)

        let isSmallDevice = UIDevice.current.userInterfaceIdiom == .phone
        let sideInset = isSmallDevice || !sectionBased ? 0 : 2 * Constants.uiPadding
        layout.sectionInsetReference = .fromSafeArea
        layout.sectionInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 3 * Constants.uiPadding, right: sideInset)

        layout.sectionHeadersPinToVisibleBounds = true

        collectionView.backgroundColor = Constants.backgroundColor
        collectionView.allowsSelection = true
        collectionView.delegate = self

        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        collectionView.refreshControl?.layoutMargins = collectionView.safeAreaInsets

        collectionView.register(GenericVideoGridCellView.self, forCellWithReuseIdentifier: GenericVideoGridCellView.identifier)
        collectionView.register(GenericVideoGridHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GenericVideoGridHeaderView.identifier)

        if fetchInitialData {
            collectionView.refreshControl?.beginRefreshing()
            setNeedsNewData()
        }

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(gestureRecognizer:)))
        collectionView.addGestureRecognizer(longPressGestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        refreshItemSize()

        if sectionBased {
            let headerContentSize = Constants.channelIconSize + 2 * Constants.uiPadding
            let topSafeAreaInset = collectionView.safeAreaInsets.top

            layout.headerReferenceSize = CGSize(width: view.bounds.width, height: headerContentSize + topSafeAreaInset)
        }
    }

    override func viewDidLoad() {
        if sectionBased {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            collectionView.contentInsetAdjustmentBehavior = .automatic
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func fetchNextData() -> SignalProducer<[GenericVideoGridViewSection], Error> {
        return SignalProducer(value: [])
    }

    func resetData() {
        return
    }

    func setNeedsNewData(clearingPreviousData: Bool = false) {
        guard !fetching else { return }
        fetching = true
        fetchNextData().startWithResult { newSectionsResult in
            DispatchQueue.main.async {
                if let newSections = newSectionsResult.value {
                    let previousData = self.sections

                    self.collectionView.performBatchUpdates({
                        // Remove previous data if required
                        if clearingPreviousData {
                            self.sections.removeAll()

                            previousData.enumerated().forEach { oldSection in
                                let (sectionIndex, element) = oldSection
                                let indexPaths = element.items.indices.map { videoIndex in
                                    return IndexPath(row: videoIndex, section: sectionIndex)
                                }
                                self.collectionView.deleteItems(at: indexPaths)
                            }

                            self.collectionView.deleteSections(IndexSet(Array(previousData.indices)))
                        }

                        // Add new data
                        self.sections += newSections

                        let newSectionsStart = self.sections.count - newSections.count
                        let newSectionsEnd = self.sections.count
                        self.collectionView.insertSections(IndexSet(Array(newSectionsStart..<newSectionsEnd)))

                        newSections.enumerated().forEach { newSection in
                            let (sectionIndex, element) = newSection

                            let indexPaths = element.items.indices.map { videoIndex in
                                return IndexPath(row: videoIndex, section: sectionIndex + newSectionsStart)
                            }
                            self.collectionView.insertItems(at: indexPaths)
                        }
                    }, completion: nil)
                }

                self.fetching = false
            }
        }
    }

    @objc func handlePullToRefresh() {
        resetData()
        setNeedsNewData(clearingPreviousData: true)
    }

    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }

        let pressLocation = gestureRecognizer.location(in: collectionView)

        guard let indexPath = collectionView.indexPathForItem(at: pressLocation) else { return }

        IncomingVideoReceiver.default.handle(
            video: sections[indexPath.section].items[indexPath.row],
            source: .rect(rect: collectionView.cellForItem(at: indexPath)?.frame ?? .zero, view: collectionView, permittedArrowDirections: [.left, .down, .up])
        )
    }
}

extension GenericVideoGridViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: GenericVideoGridCellView.identifier, for: indexPath)

        if let cell = cell as? GenericVideoGridCellView {
            cell.video = sections[indexPath.section].items[indexPath.row]
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GenericVideoGridHeaderView.identifier, for: indexPath)

            if let view = view as? GenericVideoGridHeaderView {
                view.title = sections[indexPath.section].title
                view.subtitle = sections[indexPath.section].subtitle
                view.icon = sections[indexPath.section].icon
                view.setNeedsLayout()
            }

            return view
        default:
            return UICollectionReusableView()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = sections[indexPath.section].items[indexPath.row]
        collectionView.selectItem(at: nil, animated: true, scrollPosition: .top)

        DispatchQueue.main.async {
            self.videoPlayer.playNow(video)
        }
    }
}

extension GenericVideoGridViewController: UICollectionViewDelegateFlowLayout {
    // TODO Fix this code to center the items
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        let numberOfItems = collectionView.numberOfItems(inSection: section)
//        let combinedItemWidth: CGFloat = (CGFloat(numberOfItems) * layout.itemSize.width) + ((CGFloat(numberOfItems) - 1) * layout.minimumInteritemSpacing)
//        let padding = (collectionView.contentSize.width - combinedItemWidth.truncatingRemainder(dividingBy: collectionView.contentSize.width)) / 2
//
//        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
//    }
}
