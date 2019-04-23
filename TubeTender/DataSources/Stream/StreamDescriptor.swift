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

    init(fromDict d: [String: String]) {
        url = d["url"]
        itag = d["itag"]

        let type = d["type"]?.components(separatedBy: ";+codecs=")
        mimeType = type?[0]
        if let codecString = type?[1].dropFirst(1).dropLast(1) {
            codecs = String(codecString)
        } else {
            codecs = nil
        }

        if let indexComponents = d["index"]?.components(separatedBy: "-").compactMap({ Int($0) }) {
            index = indexComponents[0]..<indexComponents[1]
        } else {
            index = nil
        }

        if let initComponents = d["init"]?.components(separatedBy: "-").compactMap({ Int($0) }) {
            initRange = initComponents[0]..<initComponents[1]
        } else {
            initRange = nil
        }

        bitrate = d["bitrate"].flatMap { UInt32($0) }
        fps = d["fps"].flatMap { UInt8($0) }

        if let sizeComponents = d["size"]?.components(separatedBy: "x") {
            width = UInt16(sizeComponents[0])
            height = UInt16(sizeComponents[1])
        } else {
            width = nil
            height = nil
        }

        qualityLabel = d["quality_label"]

        audioSampleRate = d["audio_sample_rate"].flatMap { UInt32($0) }
        audioChannels = d["audio_channels"].flatMap { UInt8($0) }
    }
}
