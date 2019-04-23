//
//  Constants.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 07.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

struct Constants {
    static let cacheLifetime: TimeInterval = 5 * 60
    static let labelColor = #colorLiteral(red: 0.3726548851, green: 0.3726548851, blue: 0.3726548851, alpha: 1)
    static let backgroundColor = #colorLiteral(red: 0.1864618063, green: 0.1864618063, blue: 0.1864618063, alpha: 1)
    static let selectedBackgroundColor = #colorLiteral(red: 0.09851306677, green: 0.09851306677, blue: 0.09851306677, alpha: 1)
    static let borderColor = Constants.labelColor
    static let primaryActionColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
    static let secondaryActionColor = #colorLiteral(red: 0.8820033277, green: 0.5383691507, blue: 0.09353697992, alpha: 1)

    static let uiPadding: CGFloat = 15.0
    static let channelIconSize: CGFloat = 45.0
    static let smallChannelIconSize: CGFloat = 35.0

    static let hlsServerPort: UInt16 = 37298
}
