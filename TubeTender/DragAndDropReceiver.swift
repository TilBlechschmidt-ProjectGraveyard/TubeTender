//
//  DragAndDropReceiver.swift
//  TubeTender
//
//  Created by Noah Peeters on 08.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class IncomingVideoReceiver: NSObject, UIDropInteractionDelegate {
    public static let `default` = IncomingVideoReceiver()

    private override init() {}

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for dragItem in session.items {
            dragItem.itemProvider.loadObject(ofClass: NSString.self) { item, _ in
                guard let receivedString = item as? NSString else { return }

                self.handle(string: receivedString as String)
            }
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }

    @objc func scanPasteboardForURL() {
        guard UIPasteboard.general.changeCount != self.pasteboardChangeCount else { return }

        self.pasteboardChangeCount = UIPasteboard.general.changeCount

        guard UIPasteboard.general.hasStrings, let urlString = UIPasteboard.general.string else { return }

        handle(string: urlString)
    }

    @discardableResult public func handle(url: URL) -> Bool {
        return handle(string: url.absoluteString)
    }

    @discardableResult public func handle(string: String) -> Bool {
        guard let url = YoutubeURL(urlString: string) else {
            return false
        }
        handle(videoURL: url)
        return true
    }

    public func handle(videoURL url: YoutubeURL) {
        SwitchablePlayer.shared.playbackItem.value = YoutubeClient.shared.video(withID: url.videoID)
        print("Found Video: \(url.videoID)")
    }

    private var pasteboardChangeCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: "pasteboardChangeCount") - 1
        }
        set {
            UserDefaults.standard.set(newValue + 1, forKey: "pasteboardChangeCount")
        }
    }
}
