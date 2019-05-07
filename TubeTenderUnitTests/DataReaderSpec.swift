//
//  DataReaderSpec.swift
//  TubeTenderUnitTests
//
//  Created by Noah Peeters on 07.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Nimble
import Quick
@testable import TubeTender

class DataReaderSpec: QuickSpec {
    override func spec() {
        describe("the data reader") {
            context("if it is not empty") {
                var dataReader: DataReader!
                beforeEach {
                    dataReader = DataReader(data: Data(0..<10))
                }

                it("returns the correct single read byte") {
                    expect(dataReader.readByte()).to(equal(0))
                }

                it("can return 1 bytes at once") {
                    expect(dataReader.read(bytes: 1)).to(equal(0))
                }

                it("can return 2 bytes at once") {
                    expect(dataReader.read(bytes: 2)).to(equal(1))
                }

                it("can return 3 bytes at once") {
                    let expectedResult: UInt64 = (1 << 8) + 2
                    expect(dataReader.read(bytes: 3)).to(equal(expectedResult))
                }

                it("can return 4 bytes at once") {
                    let expectedResult: UInt64 = (1 << 16) + (2 << 8) + 3
                    expect(dataReader.read(bytes: 4)).to(equal(expectedResult))
                }

                it("can return 5 bytes at once") {
                    let expectedResult: UInt64 = (1 << 24) + (2 << 16) + (3 << 8) + 4
                    expect(dataReader.read(bytes: 5)).to(equal(expectedResult))
                }

                context("if it is advanced by 2") {
                    beforeEach {
                        dataReader.advance(byBytes: 2)
                    }

                    it("returns the correct single read byte") {
                        expect(dataReader.readByte()).to(equal(2))
                    }
                }
            }
        }
    }
}
