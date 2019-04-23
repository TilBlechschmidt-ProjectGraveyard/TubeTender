//
//  ArrayComparable.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 04.11.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

protocol ArrayComparable: Comparable {
    static var ascendingOrder: [Self] { get }
}

extension ArrayComparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        let lhsQualityIndex = ascendingOrder.firstIndex(of: lhs) ?? 0
        let rhsQualityIndex = ascendingOrder.firstIndex(of: rhs) ?? 0
        return lhsQualityIndex < rhsQualityIndex
    }
}
