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

    private let sectionBased: Bool

    private let topSafeAreaOverlayView = UIView()

    private let videoPlayer: VideoPlayer
    private let incomingVideoReceiver: IncomingVideoReceiver
    private let layout = UICollectionViewFlowLayout()
    var sections: [GenericVideoGridViewSection] = []

    private var fetching = false

    func refreshItemSize() {
        let isSmallDevice = UIDevice.current.userInterfaceIdiom == .phone
        let frameWidth = collectionView.contentSize.width
        let defaultItemWidth = CGFloat(300.0)
        let itemPadding = isSmallDevice ? 0 : 2 * Constants.uiPadding
        let itemWidth = isSmallDevice ? frameWidth - itemPadding : defaultItemWidth
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 0.5625 + Constants.channelIconSize + 2 * Constants.uiPadding)
    }

    init(videoPlayer: VideoPlayer, incomingVideoReceiver: IncomingVideoReceiver, fetchInitialData: Bool = true, sectionBased: Bool = true) {
        self.videoPlayer = videoPlayer
        self.sectionBased = sectionBased
        self.incomingVideoReceiver = incomingVideoReceiver
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
        collectionView.refreshControl?.tintColor = .white
        collectionView.refreshControl?.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        collectionView.refreshControl?.layoutMargins = collectionView.safeAreaInsets

        collectionView.register(GenericVideoGridCellView.self, forCellWithReuseIdentifier: GenericVideoGridCellView.identifier)
        collectionView.register(GenericVideoGridHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GenericVideoGridHeaderView.identifier)

        if fetchInitialData {
            setNeedsNewData(clearingPreviousData: true)
        }

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(gestureRecognizer:)))
        collectionView.addGestureRecognizer(longPressGestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        DispatchQueue.main.async {
            self.layout.invalidateLayout()
        }
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
        if sectionBased {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if sectionBased {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
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
        if clearingPreviousData {
            collectionView.refreshControl?.beginRefreshing()
        }

        DispatchQueue.global().async {
            self.fetchNextData().observe(on: QueueScheduler.main).startWithResult { newSectionsResult in
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

                if clearingPreviousData {
                    self.collectionView.refreshControl?.endRefreshing()
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

        incomingVideoReceiver.handle(
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing
        let totalSpacing = collectionView.contentSize.width.truncatingRemainder(dividingBy: itemWidth)
        let padding = totalSpacing / 2

        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
}
