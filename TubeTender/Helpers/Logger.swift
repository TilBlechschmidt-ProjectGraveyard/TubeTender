//
//  Logger.swift
//  TubeTender
//
//  Created by Noah Peeters on 23.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    static let network = OSLog(subsystem: "de.blechschmidt.TubeTender", category: "network")
    static let googleSignIn = OSLog(subsystem: "de.blechschmidt.TubeTender", category: "google-sign-in")
    static let audio = OSLog(subsystem: "de.blechschmidt.TubeTender", category: "audio")
}
