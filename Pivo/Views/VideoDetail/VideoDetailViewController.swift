//
//  ViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 11.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import UIKit
import YoutubeKit
import SkeletonView

class VideoDetailViewController: UIViewController {
    var interactor: Interactor?

    let uiPadding: CGFloat = 15.0
    let channelIconSize: CGFloat = 35.0
    let borderColor = UIColor(red: 0.141, green: 0.141, blue: 0.141, alpha: 1)

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = "."
        formatter.numberStyle = .decimal
        return formatter
    }()

    private let player: PlayerView = PlayerView()

    private let metaScrollView = UIScrollView()
    private let metaView = UIView()

    // Video detail
    private let detailView = UIView()
    private let videoTitle = UILabel()
    private let viewCount = UILabel()

    // Channel
    private let channelView = UIView()
    private let channelThumbnail = UIImageView()
    private let channelTitle = UILabel()
    private let channelSubscriberCount = UILabel()

    // Description
    private let descriptionView = UIView()
    private let videoDescriptionView = UITextView()

    private var _videoID: String!
    var videoID: String! {
        get {
            return _videoID
        }
        set {
            _videoID = newValue
            fetchVideoDetails()
        }
    }

    var aspectRatioConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    var metaPositionConstraint: NSLayoutConstraint!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return player.isFullscreen
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)

        setupPlayer()

        setupMetaScrollView()

        setupVideoDetails()
        setupChannelDetails()
        setupVideoDescription()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(VideoDetailViewController.handleGesture(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = true
        panGesture.delaysTouchesEnded = true
        player.addGestureRecognizer(panGesture)
    }

    func setupMetaScrollView() {
        let metaScrollViewContainer = UIView()
        view.addSubview(metaScrollViewContainer)
        metaScrollViewContainer.translatesAutoresizingMaskIntoConstraints = false
        metaScrollViewContainer.clipsToBounds = true
        view.addConstraints([
            metaScrollViewContainer.topAnchor.constraint(equalTo: player.bottomAnchor),
            metaScrollViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metaScrollViewContainer.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])

        metaScrollViewContainer.addSubview(metaScrollView)

        metaScrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        metaScrollView.addSubview(metaView)
        metaView.translatesAutoresizingMaskIntoConstraints = false
        metaScrollView.addConstraints([
            metaView.topAnchor.constraint(equalTo: metaScrollView.topAnchor),
            metaView.bottomAnchor.constraint(equalTo: metaScrollView.bottomAnchor)
        ])
        metaScrollViewContainer.addConstraints([
            metaView.leadingAnchor.constraint(equalTo: metaScrollViewContainer.leadingAnchor),
            metaView.trailingAnchor.constraint(equalTo: metaScrollViewContainer.trailingAnchor)
        ])
    }

    func setupPlayer() {
        // Add the player
        view.addSubview(player)

        // Place the player at the top
        player.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            player.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            player.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            player.widthAnchor.constraint(equalTo: view.widthAnchor),
            player.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor),
            player.heightAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.5625)
        ])

        // Add optional requirement for player to be 16:9
        let constr = player.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5625)
        constr.priority = .defaultHigh
        constr.isActive = true

        // Add a little black bar above the player
        let blackBar = UIView()
        blackBar.backgroundColor = UIColor.black
        view.addSubview(blackBar)
        blackBar.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            blackBar.topAnchor.constraint(equalTo: view.topAnchor),
            blackBar.widthAnchor.constraint(equalTo: view.widthAnchor),
            blackBar.bottomAnchor.constraint(equalTo: player.topAnchor),
        ])

        YoutubeCrawler.streamManager(forVideoID: videoID) { streamManager in
            self.player.streamManager = streamManager
        }
    }

    func setupVideoDetails() {
        detailView.translatesAutoresizingMaskIntoConstraints = false
        metaView.addSubview(detailView)
        metaView.addConstraints([
            detailView.topAnchor.constraint(equalTo: metaView.topAnchor),
            detailView.leftAnchor.constraint(equalTo: metaView.leftAnchor),
            detailView.rightAnchor.constraint(equalTo: metaView.rightAnchor)
        ])

        videoTitle.font = videoTitle.font.withSize(13)
        videoTitle.textColor = UIColor.white
        videoTitle.lineBreakMode = .byTruncatingTail
        detailView.addSubview(videoTitle)
        videoTitle.translatesAutoresizingMaskIntoConstraints = false
        detailView.addConstraints([
            videoTitle.topAnchor.constraint(equalTo: detailView.topAnchor, constant: uiPadding),
            videoTitle.leftAnchor.constraint(equalTo: detailView.leftAnchor, constant: uiPadding),
            videoTitle.rightAnchor.constraint(equalTo: detailView.rightAnchor, constant: -uiPadding)
        ])

        viewCount.font = viewCount.font.withSize(11)
        viewCount.textColor = UIColor.lightGray
        detailView.addSubview(viewCount)
        viewCount.translatesAutoresizingMaskIntoConstraints = false
        detailView.addConstraints([
            viewCount.topAnchor.constraint(equalTo: videoTitle.bottomAnchor, constant: uiPadding / 2),
            viewCount.leftAnchor.constraint(equalTo: videoTitle.leftAnchor),
            viewCount.rightAnchor.constraint(equalTo: videoTitle.rightAnchor),
            viewCount.bottomAnchor.constraint(equalTo: detailView.bottomAnchor, constant: -uiPadding),
        ])
    }

    func setupChannelDetails() {
        channelView.isSkeletonable = true
        channelView.translatesAutoresizingMaskIntoConstraints = false
        metaView.addSubview(channelView)
        metaView.addConstraints([
            channelView.topAnchor.constraint(equalTo: detailView.bottomAnchor),
            channelView.leftAnchor.constraint(equalTo: metaView.leftAnchor),
            channelView.rightAnchor.constraint(equalTo: metaView.rightAnchor),
        ])

        let topBorder = UIView()
        topBorder.backgroundColor = borderColor
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        channelView.addSubview(topBorder)
        channelView.addConstraints([
            topBorder.topAnchor.constraint(equalTo: channelView.topAnchor),
            topBorder.widthAnchor.constraint(equalTo: channelView.widthAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 1)
        ])

        let bottomBorder = UIView()
        bottomBorder.backgroundColor = borderColor
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        channelView.addSubview(bottomBorder)
        channelView.addConstraints([
            bottomBorder.bottomAnchor.constraint(equalTo: channelView.bottomAnchor),
            bottomBorder.widthAnchor.constraint(equalTo: channelView.widthAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1)
        ])

        channelThumbnail.isSkeletonable = true
        channelThumbnail.backgroundColor = UIColor.lightGray
        channelThumbnail.layer.cornerRadius = channelIconSize / 2
        channelThumbnail.layer.masksToBounds = false
        channelThumbnail.clipsToBounds = true
        channelThumbnail.translatesAutoresizingMaskIntoConstraints = false
        channelView.addSubview(channelThumbnail)
        channelView.addConstraints([
            channelThumbnail.widthAnchor.constraint(equalToConstant: channelIconSize),
            channelThumbnail.heightAnchor.constraint(equalToConstant: channelIconSize),
            channelThumbnail.topAnchor.constraint(equalTo: channelView.topAnchor, constant: uiPadding),
            channelThumbnail.leftAnchor.constraint(equalTo: channelView.leftAnchor, constant: uiPadding),
            channelThumbnail.bottomAnchor.constraint(equalTo: channelView.bottomAnchor, constant: -uiPadding)
        ])

        let channelDetailLabelView = UIView()
        channelDetailLabelView.isSkeletonable = true
        channelDetailLabelView.translatesAutoresizingMaskIntoConstraints = false
        channelView.addSubview(channelDetailLabelView)
        channelView.addConstraints([
            channelDetailLabelView.leftAnchor.constraint(equalTo: channelThumbnail.rightAnchor, constant: uiPadding),
            channelDetailLabelView.rightAnchor.constraint(equalTo: channelView.rightAnchor, constant: -uiPadding),
            channelDetailLabelView.centerYAnchor.constraint(equalTo: channelThumbnail.centerYAnchor)
        ])

        channelTitle.isSkeletonable = true
        channelTitle.font = channelTitle.font.withSize(13)
        channelTitle.textColor = UIColor.white
        channelTitle.lineBreakMode = .byTruncatingTail
        channelTitle.translatesAutoresizingMaskIntoConstraints = false
        channelDetailLabelView.addSubview(channelTitle)
        channelDetailLabelView.addConstraints([
            channelTitle.leftAnchor.constraint(equalTo: channelDetailLabelView.leftAnchor),
            channelTitle.rightAnchor.constraint(equalTo: channelDetailLabelView.rightAnchor),
            channelTitle.topAnchor.constraint(equalTo: channelDetailLabelView.topAnchor)
        ])

        channelSubscriberCount.isSkeletonable = true
        channelSubscriberCount.font = channelTitle.font.withSize(11)
        channelSubscriberCount.textColor = UIColor.lightGray
        channelSubscriberCount.lineBreakMode = .byTruncatingTail
        channelSubscriberCount.translatesAutoresizingMaskIntoConstraints = false
        channelDetailLabelView.addSubview(channelSubscriberCount)
        channelDetailLabelView.addConstraints([
            channelSubscriberCount.leftAnchor.constraint(equalTo: channelDetailLabelView.leftAnchor),
            channelSubscriberCount.rightAnchor.constraint(equalTo: channelDetailLabelView.rightAnchor),
            channelSubscriberCount.bottomAnchor.constraint(equalTo: channelDetailLabelView.bottomAnchor),
            channelSubscriberCount.topAnchor.constraint(equalTo: channelTitle.bottomAnchor, constant: uiPadding / 4)
        ])
    }

    func setupVideoDescription() {
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        metaView.addSubview(descriptionView)
        metaView.addConstraints([
            descriptionView.topAnchor.constraint(equalTo: channelView.bottomAnchor),
            descriptionView.leftAnchor.constraint(equalTo: metaView.leftAnchor),
            descriptionView.rightAnchor.constraint(equalTo: metaView.rightAnchor),
            descriptionView.bottomAnchor.constraint(equalTo: metaView.bottomAnchor)
        ])

        videoDescriptionView.font = videoDescriptionView.font?.withSize(12)
        videoDescriptionView.textColor = UIColor.lightGray
        videoDescriptionView.isEditable = false
        videoDescriptionView.dataDetectorTypes = .all
        videoDescriptionView.isScrollEnabled = false
        videoDescriptionView.backgroundColor = nil
        videoDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        descriptionView.addSubview(videoDescriptionView)
        descriptionView.addConstraints([
            videoDescriptionView.topAnchor.constraint(equalTo: descriptionView.topAnchor, constant: uiPadding),
            videoDescriptionView.leftAnchor.constraint(equalTo: descriptionView.leftAnchor, constant: uiPadding),
            videoDescriptionView.rightAnchor.constraint(equalTo: descriptionView.rightAnchor, constant: -uiPadding),
            videoDescriptionView.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: -uiPadding)
        ])
    }

    func fetchVideoDetails() {
        let request = VideoListRequest(part: [.snippet, .statistics], filter: .id(videoID))

        ApiSession.shared.send(request) { result in
            switch result {
            case .success(let response):
                if let snippet = response.items.first?.snippet, let stats = response.items.first?.statistics {
                    self.videoTitle.text = snippet.title

                    if let views = Int(stats.viewCount),
                        let viewsString = VideoDetailViewController.numberFormatter.string(from: NSNumber(value: views)) {
                        self.viewCount.text = "\(viewsString) views"
                    }

                    self.videoDescriptionView.text = snippet.description

                    self.fetchChannelDetails(forID: snippet.channelID)
                }
            case .failed(let error):
                // TODO Show error message
                print(error)
            }
        }
    }

    func fetchChannelDetails(forID channelID: String) {
        let request = ChannelListRequest(part: [.snippet, .statistics, .topicDetails], filter: .id(channelID))

        ApiSession.shared.send(request) { result in
            switch result {
            case .success(let response):
                if let snippet = response.items.first?.snippet, let stats = response.items.first?.statistics {

                    self.channelTitle.text = snippet.title

                    if let subscriberCount = Int(stats.subscriberCount) {
                        self.channelSubscriberCount.text = "\(subscriberCount.unitFormatted) subscribers"
                    }

                    if let thumbnailURL = snippet.thumbnails.default.url {
                        self.channelThumbnail.downloaded(from: thumbnailURL)
                    }
                }
            case .failed(let error):
                // TODO Show error message
                print(error)
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        let orientation: UIDeviceOrientation = UIDevice.current.orientation

        switch (orientation) {
        case .portrait, .portraitUpsideDown:
            player.isFullscreen = false
        case .landscapeRight, .landscapeLeft:
            player.isFullscreen = true
        default:
            break
        }

        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    @objc func handleGesture(_ sender: UIPanGestureRecognizer) {

        let percentThreshold:CGFloat = 0.3

        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)

        guard let interactor = interactor else { return }

        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish
                ? interactor.finish()
                : interactor.cancel()
        default:
            break
        }
    }
}
