//
//  StreamDescriptor.swift
//  HLSServer
//
//  Created by Til Blechschmidt on 20.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

struct StreamDescriptor {
    let url: String!
    let itag: String!
    let mimeType: String!
    let codecs: String!

    let index: Range<Int>!
    let initRange: Range<Int>!

    let bitrate: UInt32!
    let fps: UInt8!

    let width: UInt16?
    let height: UInt16?

    let qualityLabel: String?

    let audioSampleRate: UInt32?
    let audioChannels: UInt8?

    init(fromDict data: [String: String]) {
        url = data["url"]
        itag = data["itag"]

        let type = data["type"]?.components(separatedBy: ";+codecs=")
        mimeType = type?[0]
        if let codecString = type?[1].dropFirst(1).dropLast(1) {
            codecs = String(codecString)
        } else {
            codecs = nil
        }

        if let indexComponents = data["index"]?.components(separatedBy: "-").compactMap(Int.init) {
            index = indexComponents[0]..<indexComponents[1]
        } else {
            index = nil
        }

        if let initComponents = data["init"]?.components(separatedBy: "-").compactMap(Int.init) {
            initRange = initComponents[0]..<initComponents[1]
        } else {
            initRange = nil
        }

        bitrate = data["bitrate"].flatMap(UInt32.init)
        fps = data["fps"].flatMap(UInt8.init)

        if let sizeComponents = data["size"]?.components(separatedBy: "x") {
            width = UInt16(sizeComponents[0])
            height = UInt16(sizeComponents[1])
        } else {
            width = nil
            height = nil
        }

        qualityLabel = data["quality_label"]

        audioSampleRate = data["audio_sample_rate"].flatMap(UInt32.init)
        audioChannels = data["audio_channels"].flatMap(UInt8.init)
    }
}
