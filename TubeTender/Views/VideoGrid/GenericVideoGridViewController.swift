//
//  VideoGridViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 02.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import SnapKit
import UIKit

struct GenericVideoGridViewSection {
    let title: String
    let subtitle: String?
    let icon: URL?
    let items: [Video]
}

class GenericVideoGridViewController: UICollectionViewController {
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

    init(videoPlayer: VideoPlayer) {
        self.videoPlayer = videoPlayer
        super.init(collectionViewLayout: layout)

        let itemWidth = CGFloat(300.0)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 2 * Constants.uiPadding, bottom: 3 * Constants.uiPadding, right: 2 * Constants.uiPadding)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 0.5625 + Constants.channelIconSize + 2 * Constants.uiPadding)
        layout.headerReferenceSize = CGSize(width: view.bounds.width, height: Constants.channelIconSize + 2 * Constants.uiPadding)

        collectionView.backgroundColor = Constants.backgroundColor
        collectionView.allowsSelection = true

        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)

        collectionView.register(GenericVideoGridViewCell.self, forCellWithReuseIdentifier: GenericVideoGridViewCell.identifier)
        collectionView.register(GenericVideoGridSupplimentaryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GenericVideoGridSupplimentaryView.identifier)

        collectionView.refreshControl?.beginRefreshing()
        setNeedsNewData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            if let newSections = newSectionsResult.value {
                DispatchQueue.main.sync {
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
            }

            self.fetching = false
        }
    }

    @objc func handlePullToRefresh() {
        resetData()
        setNeedsNewData(clearingPreviousData: true)
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
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: GenericVideoGridViewCell.identifier, for: indexPath)

        if let cell = cell as? GenericVideoGridViewCell {
            cell.video = sections[indexPath.section].items[indexPath.row]
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GenericVideoGridSupplimentaryView.identifier, for: indexPath)

            if let view = view as? GenericVideoGridSupplimentaryView {
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

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section >= sections.count - 2 {
            setNeedsNewData()
        }
    }
}

class GenericVideoGridSupplimentaryView: UICollectionReusableView {
    static let kind: String = "GenericTitle"
    static let identifier: String = "GenericVideoGridSupplimentaryView"

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let topBorder = UIView()
    let iconView = UIImageView()

    var iconVisibleConstraint: Constraint!
    var iconHiddenConstraint: Constraint!

    var icon: URL? {
        didSet {
            iconView.image = nil
            iconView.kf.cancelDownloadTask()
            iconView.kf.setImage(with: icon)

            if icon == nil {
                iconVisibleConstraint.deactivate()
                iconHiddenConstraint.activate()
            } else {
                iconHiddenConstraint.deactivate()
                iconVisibleConstraint.activate()
            }
        }
    }

    var title: String! {
        didSet {
            titleLabel.text = title
        }
    }

    var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    func setupUI() {
        topBorder.backgroundColor = Constants.selectedBackgroundColor
        addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(1)
        }

        titleLabel.textColor = .white

        subtitleLabel.textColor = Constants.borderColor
        subtitleLabel.font = subtitleLabel.font.withSize(14)

        iconView.layer.cornerRadius = Constants.channelIconSize / 2
        iconView.layer.masksToBounds = false
        iconView.clipsToBounds = true

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        stackView.spacing = Constants.uiPadding
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.left.equalToSuperview().offset(Constants.uiPadding)
        }

        iconView.snp.makeConstraints { make in
            make.height.equalTo(Constants.channelIconSize)
        }

        iconView.snp.prepareConstraints { make in
            iconVisibleConstraint = make.width.equalTo(Constants.channelIconSize).constraint
            iconHiddenConstraint = make.width.equalTo(0).constraint
        }

        iconHiddenConstraint.activate()
    }
}

class GenericVideoGridViewCell: UICollectionViewCell {
    static let identifier: String = "GenericVideoGridViewCell"

    let videoCellView = VideoCellView()

    var video: Video! {
        didSet {
            videoCellView.video = video
        }
    }

    var hideThumbnail: Bool = false {
        didSet {
            videoCellView.hideThumbnail = hideThumbnail
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = Constants.selectedBackgroundColor

        addSubview(videoCellView)
        videoCellView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
