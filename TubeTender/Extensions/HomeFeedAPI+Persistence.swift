//
//  HomeFeedAPI+Persistence.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 02.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

private let cookieDomain: String = ".youtube.com"
private let requiredCookies: [String] = ["SIDCC", "PREF", "VISITOR_INFO1_LIVE", "YSC", "APISID", "CONSENT", "HSID", "SAPISID", "SID", "SSID", "LOGIN_INFO"]

extension HomeFeedAPI {
    convenience init?() {
        guard let cookies = HTTPCookieStorage.shared.cookies?.filter({ requiredCookies.contains($0.name) && $0.domain == cookieDomain }) else {
            return nil
        }

        self.init(cookies: cookies)
    }
}
