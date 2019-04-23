//
//  VideoDownloadButtonViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 04.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import DownloadButton
import os.log
import ReactiveSwift
import UIKit

class VideoDownloadButtonViewController: UIViewController {
    var video: Video! {
        didSet {
            switch DownloadManager.shared.status(forVideoWithID: video.id) {
            case .downloaded:
                downloadButton.isDownloaded = true
            case .inProgress(let progressSignal):
                downloadProgressSignal = progressSignal
            case .notStored:
                downloadButton.downloadState = .toDownload
            case .stalled:
                // TODO Indicate the stall in the UI
                downloadButton.downloadState = .toDownload
            }
        }
    }

    let downloadButton = NFDownloadButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

    private var downloadProgressSignal: Signal<Double, DownloadManagerError>! {
        willSet {
            let signalVideoID = video.id
            newValue
                .take { _ in signalVideoID == self.video.id }
                .take(duringLifetimeOf: self)
                .observeResult { [unowned self] result in
                    switch result {
                    case .success(let progress):
                        DispatchQueue.main.async {
                            if self.downloadButton.downloadState != .readyToDownload {
                                self.downloadButton.downloadState = .readyToDownload
                            }
                            self.downloadButton.downloadPercent = CGFloat(progress)
                        }
                    case .failure(let error):
                        os_log("Download video error: %@", log: .network, type: .info, error.localizedDescription)
                    }
            }
        }
    }

    override func viewDidLoad() {
        view.addSubview(downloadButton)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            downloadButton.topAnchor.constraint(equalTo: view.topAnchor),
            downloadButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            downloadButton.leftAnchor.constraint(equalTo: view.leftAnchor),
            downloadButton.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        downloadButton.addTarget(self, action: #selector(self.onDownloadTap), for: .touchUpInside)
    }

    func deleteDownload() {
        let alert = UIAlertController(title: "Delete video", message: "Do you want to remove the downloaded video?", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive) { _ in
            if DownloadManager.shared.removeDownload(withID: self.video.id) == nil {
                DispatchQueue.main.async {
                    self.downloadButton.downloadState = .toDownload
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    @objc func onDownloadTap() {
        switch DownloadManager.shared.status(forVideoWithID: video.id) {
        case .downloaded:
            deleteDownload()
        case .inProgress:
            // TODO Cancel the download
            break
        case .stalled:
            // TODO Resume or delete the download
            break
        case .notStored:
            downloadButton.downloadState = .willDownload
            downloadProgressSignal = DownloadManager.shared.downloadVideo(withID: video.id)
        }
    }
}
