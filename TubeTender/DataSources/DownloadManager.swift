//
//  DownloadManager.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 02.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Alamofire
import ReactiveSwift
import YoutubeKit
import CoreStore
import Result

fileprivate struct Static {
    static let downloadManagerStack: DataStack = {
        let dataStack = DataStack()
        try! dataStack.addStorageAndWait(
            SQLiteStore(
                fileName: "DownloadManager.sqlite",
                localStorageOptions: .allowSynchronousLightweightMigration
            )
        )
        return dataStack
    }()
}

fileprivate func downloadedContentDirectory() -> URL? {
    let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    let bundleID = Bundle.main.bundleIdentifier
    let directoryName = "DownloadedContent"
    let downloadsURL = bundleID.flatMap {
        applicationSupportURL?
            .appendingPathComponent($0, isDirectory: true)
            .appendingPathComponent(directoryName, isDirectory: true)
    }
    return downloadsURL
}

extension DataStack {
    func createSignalProducer<T>(asynchronous task: @escaping (AsynchronousDataTransaction) throws -> T) -> SignalProducer<T, CoreStoreError> {
        return SignalProducer<T, CoreStoreError>() { observer, _ in
            self.perform(
                asynchronous: task,
                success: { value in
                    observer.send(value: value)
                    observer.sendCompleted()
                },
                failure: { error in
                    observer.send(error: error)
                }
            )
        }
    }
}

//extension SignalProducer {
//    func discardValue<F>(_: F.Type = F.self) -> SignalProducer<Never, F> {
//        return SignalProducer<Never, F>() { observer, _ in
//            self.startWithSignal { signal, disposable -> Disposable in
//                signal.observe { event in
//                    if event.isCompleted { observer.sendCompleted() }
//                    else if event.isTerminating { observer.sendInterrupted() }
////                    else if let error = event.error { observer.send(error: error) }
//                }
//                return disposable
//            }
//        }
//    }
//}

enum DownloadManagerError: Error {
    case notDownloaded
    case failedToDelete(fileManagerError: Error)
    case database(error: CoreStoreError)
    case videoStreamAPI(error: VideoStreamAPIError)
    case videoMetadataAPI(error: VideoMetadataAPIError)
    case channelMetadataAPI(error: ChannelMetadataAPIError)
}

enum DownloadStatus {
    case downloaded
    case inProgress(progressSignal: Signal<Double, DownloadManagerError>)
    case stalled
    case notStored
}

class DownloadManager {
    static let shared = DownloadManager()

    private init() { }

    var currentlyDownloading: [VideoID : Signal<Double, DownloadManagerError>] = [:]

    public func status(forVideoWithID videoID: VideoID) -> DownloadStatus {
        let completedStatus = Static.downloadManagerStack.queryValue(
            From<DownloadedVideo>().select(\.completed).where(\.id == videoID)
        )

        if let status = completedStatus {
            if !status, let progressSignal = currentlyDownloading[videoID] {
                return .inProgress(progressSignal: progressSignal)
            } else if !status {
                return .stalled
            } else {
                return .downloaded
            }
        } else {
            return .notStored
        }
    }

    public func removeDownload(withID videoID: VideoID) -> DownloadManagerError? {
        let containerPath = containerPathForVideo(withID: videoID)!

        guard FileManager.default.fileExists(atPath: containerPath.path) else {
            return DownloadManagerError.notDownloaded
        }

        do {
            try FileManager.default.removeItem(at: containerPath)
            _ = try Static.downloadManagerStack.perform(synchronous: { transaction in
                transaction.deleteAll(From<DownloadedVideo>().where(\.id == videoID))
            })
        } catch (let error) {
            return DownloadManagerError.failedToDelete(fileManagerError: error)
        }

        return nil
    }

    public func downloadVideo(withID videoID: VideoID) -> Signal<Double, DownloadManagerError> {
        let databaseInsertion = Static.downloadManagerStack.createSignalProducer { transaction in
            let video = transaction.create(Into<DownloadedVideo>())
            video.id = videoID
            video.completed = false
            video.downloadedAt = Date()
        }.mapError { DownloadManagerError.database(error: $0)}

        let streamManagerTask = VideoStreamAPI.shared.streamManager(forVideoID: videoID).mapError { videoStreamAPIError in
            return DownloadManagerError.videoStreamAPI(error: videoStreamAPIError)
        }

        let downloadTaskClosure: (VideoStreamManager) -> SignalProducer<Double, DownloadManagerError> = { streamManager in
            let videoURLString = try! streamManager.stream(withPreferredQuality: .hd720, adaptive: false).video.url
            let videoURL = URL(string: videoURLString)!

            return self.downloadTaskForVideo(withID: videoID, withURL: videoURL).on(
                completed: {
                    Static.downloadManagerStack.createSignalProducer { transaction in
                        if let video = transaction.fetchOne(From<DownloadedVideo>().where(\.id == videoID)) {
                            video.completed = true
                        }
                    }.start()
                    self.currentlyDownloading.removeValue(forKey: videoID)
                }
            )
        }

        let metadataTask = downloadMetadataForVideo(withID: videoID)

        let downloadSignalProducer = databaseInsertion
            .then(metadataTask)
            .then(streamManagerTask)
            .flatMap(.concat, downloadTaskClosure)

        return downloadSignalProducer.startWithSignal { signal, _ in
            currentlyDownloading.updateValue(signal, forKey: videoID)
            return signal
        }
    }

    private func containerPathForVideo(withID videoID: VideoID) -> URL? {
        let directoryURL = downloadedContentDirectory()
        let containerName = "\(videoID)"
        return directoryURL?.appendingPathComponent(containerName, isDirectory: true)
    }

    private func downloadDestinationURL(forVideoID videoID: VideoID, withFilename fileName: String) -> URL? {
        return self.containerPathForVideo(withID: videoID)?.appendingPathComponent(fileName)
    }

    private func downloadDestination(forVideoID videoID: VideoID, withFilename fileName: String) -> DownloadRequest.DownloadFileDestination {
        return { (temporaryURL, response) in
            return (
                self.downloadDestinationURL(forVideoID: videoID, withFilename: fileName)!,
                [.removePreviousFile, .createIntermediateDirectories]
            )
        }
    }

    private func downloadTaskForVideo(withID videoID: VideoID, withURL videoURL: URL) -> SignalProducer<Double, DownloadManagerError> {
        let destination = downloadDestination(forVideoID: videoID, withFilename: "video")

        return SignalProducer<Double, DownloadManagerError>() { observer, _ in
            Alamofire.download(videoURL, to: destination)
                .downloadProgress(queue: DispatchQueue.global()) { progress in
                    observer.send(value: progress.fractionCompleted)
                }
                .response { response in
//                    print("Error: \(response.error)")
                    // TODO Handle error if it occurs
                    observer.sendCompleted()
            }
        }
    }

    private func downloadMetadataForVideo(withID videoID: VideoID) -> SignalProducer<Never, DownloadManagerError> {
        return VideoMetadataAPI.shared.fetchMetadata(forVideo: videoID).map { metadata in
            let path = self.downloadDestinationURL(forVideoID: videoID, withFilename: "videoMetadata.json")
            let data = try? JSONEncoder().encode(metadata)
            path.flatMap { try? data?.write(to: $0, options: []) }
            return metadata
        }
            .mapError { DownloadManagerError.videoMetadataAPI(error: $0) }
            .flatMap(.concat) { videoMetadata in
                self.downloadThumbnail(forVideo: videoMetadata, withID: videoID)
                    .then(self.downloadMetadataForChannel(withID: videoMetadata.snippet!.channelID, withVideoID: videoID))
            }
    }

    private func downloadThumbnail(forVideo video: Video, withID videoID: VideoID) -> SignalProducer<Never, DownloadManagerError> {
        return SignalProducer<Never, DownloadManagerError>() { observer, _ in
            let thumbnailString = video.snippet?.thumbnails.high.url
            let thumbnailURL = URL(string: thumbnailString!)
            let destination = self.downloadDestination(forVideoID: videoID, withFilename: "videoThumb")

            Alamofire.download(thumbnailURL!, to: destination)
                .response { response in
                    observer.sendCompleted()
                }
        }
    }

    private func downloadMetadataForChannel(withID channelID: ChannelID, withVideoID videoID: VideoID) -> SignalProducer<Never, DownloadManagerError> {
        return ChannelMetadataAPI.shared.fetchMetadata(forChannel: channelID).map { metadata in
            let path = self.downloadDestinationURL(forVideoID: videoID, withFilename: "channelMetadata.json")
            let data = try? JSONEncoder().encode(metadata)
            path.flatMap { try? data?.write(to: $0, options: []) }
            return metadata
        }
            .mapError { DownloadManagerError.channelMetadataAPI(error: $0) }
            .flatMap(.concat) {
                self.downloadThumbnail(forChannel: $0, withVideoID: videoID)
            }
    }

    private func downloadThumbnail(forChannel channel: Channel, withVideoID videoID: VideoID) -> SignalProducer<Never, DownloadManagerError> {
        return SignalProducer<Never, DownloadManagerError>() { observer, _ in
            let thumbnailString = channel.snippet?.thumbnails.high.url
            let thumbnailURL = URL(string: thumbnailString!)
            let destination = self.downloadDestination(forVideoID: videoID, withFilename: "channelThumb")

            Alamofire.download(thumbnailURL!, to: destination)
                .response { response in
                    observer.sendCompleted()
                }
        }
    }
}
