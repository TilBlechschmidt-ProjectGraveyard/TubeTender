//
//  IncomingVideoReceiver.swift
//  TubeTender
//
//  Created by Noah Peeters on 08.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import ReactiveSwift
import UIKit
import CoreGraphics

enum VideoSource {
    case none
    case view(view: UIView, permittedArrowDirections: UIPopoverArrowDirection)
    case rect(rect: CGRect, view: UIView, permittedArrowDirections: UIPopoverArrowDirection)

    var isNone: Bool {
        switch self {
        case .none:
            return true
        default:
            return false
        }
    }
}

class IncomingVideoReceiver: NSObject {
    public static let `default` = IncomingVideoReceiver()

    override private init() {}

    @discardableResult public func handle(url: URL, source: VideoSource) -> Bool {
        return handle(string: url.absoluteString, source: source)
    }

    @discardableResult public func handle(string: String, source: VideoSource) -> Bool {
        guard let url = YoutubeURL(urlString: string) else {
            return false
        }
        handle(videoURL: url, source: source)
        return true
    }

    public func handle(videoURL url: YoutubeURL, source: VideoSource) {
        handle(video: YoutubeClient.shared.video(withID: url.videoID), source: source)
    }

    public func handle(video: Video, source: VideoSource) {
        DispatchQueue.main.async {
            let alertControl = UIAlertController(
                title: "Loading\n...\n...",
                message: nil,
                preferredStyle: source.isNone ? .alert : .actionSheet)

            alertControl.reactive.attributedTitle <~ SignalProducer(value: "How do you want to play the video?")
                    .then(video.title)
                    .filterMap { $0.value }
                    .map {
                        return NSAttributedString(string: $0, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
                    }

            alertControl.popoverPresentationController?.backgroundColor = Constants.selectedBackgroundColor.withAlphaComponent(0.75)
            alertControl.view.tintColor = .lightGray

            alertControl.addAction(UIAlertAction(title: "Play Now", style: .default) { _ in
                VideoPlayer.shared.playNow(video)
            })
            alertControl.addAction(UIAlertAction(title: "Play Next", style: .default) { _ in
                VideoPlayer.shared.playNext(video)
            })
            alertControl.addAction(UIAlertAction(title: "Play Later", style: .default) { _ in
                VideoPlayer.shared.playLater(video)
            })
            alertControl.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            guard let rootViewController = (UIApplication.shared.delegate?.window ?? nil)?.rootViewController else { return }

            switch source {
            case let .view(view, permittedArrowDirections):
                alertControl.popoverPresentationController?.sourceView = view
                alertControl.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
            case let .rect(rect, view, permittedArrowDirections):
                alertControl.popoverPresentationController?.sourceView = view
                alertControl.popoverPresentationController?.sourceRect = rect
                alertControl.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
            default:
                break
            }

            rootViewController.present(alertControl, animated: true, completion: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                alertControl.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension IncomingVideoReceiver: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for dragItem in session.items {
            dragItem.itemProvider.loadObject(ofClass: NSString.self) { item, _ in
                guard let receivedString = item as? NSString else { return }

                self.handle(string: receivedString as String, source: .none)
            }
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
}

extension IncomingVideoReceiver {
    private var pasteboardChangeCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: "pasteboardChangeCount") - 1
        }
        set {
            UserDefaults.standard.set(newValue + 1, forKey: "pasteboardChangeCount")
        }
    }

    @objc func scanPasteboardForURL() {
        guard UIPasteboard.general.changeCount != self.pasteboardChangeCount else { return }

        self.pasteboardChangeCount = UIPasteboard.general.changeCount

        guard UIPasteboard.general.hasStrings, let urlString = UIPasteboard.general.string else { return }

        handle(string: urlString, source: .none)
    }
}
