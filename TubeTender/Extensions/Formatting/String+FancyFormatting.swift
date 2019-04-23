//
//  String+FancyFormatting.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 17.10.18.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

private let thousandLimit = 1000
private let millionLimit = 1000 * 1000
private let billionLimit = 1000 * 1000 * 1000

extension Int {
    var withThousandSeparators: String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = "."
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }

    var unitFormatted: String {
        if self < thousandLimit {
            return String(self)
        } else if self < millionLimit {
            return "\(self / thousandLimit)K"
        } else if self < billionLimit {
            return "\(self / millionLimit)M"
        } else if self < billionLimit * 1000 {
            return "\(self / billionLimit)B"
        } else {
            let formatter = NumberFormatter()
            formatter.groupingSeparator = "."
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: self)) ?? String(self)
        }
    }
}
