//
//  Optional+Error.swift
//  TubeTender
//
//  Created by Noah Peeters on 07.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

extension Optional {
    func unwrap<E: Error>(_ error: E) throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw error
        }
    }
}
