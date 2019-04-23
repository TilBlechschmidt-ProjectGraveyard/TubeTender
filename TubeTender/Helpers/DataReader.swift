//
//  DataReader.swift
//  HLSServer
//
//  Created by Til Blechschmidt on 20.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

class DataReader {
    let data: Data
    var offset: Int

    init(data: Data, offset: Int = 0) {
        self.data = data
        self.offset = offset
    }

    func advance(by: Int) {
        offset += by
    }

    func readByte() -> UInt8 {
        let byte = data[offset]
        offset += 1
        return byte
    }

    func read(bytes: UInt8) -> UInt64 {
        return (0..<bytes).reduce(0) { acc, byteIndex in
            let byte = readByte()
            let shift = (bytes - 1 - byteIndex) * 8
            return acc | (UInt64(byte) << shift)
        }
    }
}
