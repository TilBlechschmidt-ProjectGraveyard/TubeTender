//
//  Queue.swift
//  Pivo
//
//  Created by Til Blechschmidt on 05.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

class Queue<T> {
    var list = [T]()
    
    var isEmpty: Bool {
        return list.isEmpty
    }

    func enqueue(_ element: T) {
        list.append(element)
    }

    func dequeue() -> T? {
        if !list.isEmpty {
            return list.removeFirst()
        } else {
            return nil
        }
    }

    func peek() -> T? {
        if !list.isEmpty {
            return list[0]
        } else {
            return nil
        }
    }

    func insert(_ element: T, at: Int) {
        list.insert(element, at: at)
    }
}
